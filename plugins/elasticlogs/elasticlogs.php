<?php
declare(strict_types=1);
require_once(__DIR__ . "/vendor/autoload.php");

use Elastic\Elasticsearch\ClientBuilder;

/**
 * Elasticlogs Plugin for Roundcube
 *
 * @author Sérgio Carvalho <daf@sooma.com>
 *
 * Copyright (C) Sooma.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */
class elasticlogs extends rcube_plugin
{
    public $task = '?(?!login|logout).*';
    public $rc;

    private const ES_QUERY_SIZE = 1000;

    private const ES_SOURCE_FIELDS = [
        '@timestamp',
        'host.hostname',
        'message',
        'postfix.queueid',
        'postfix.message-id',
        'postfix.from',
        'postfix.kv.to',
        'postfix.status',
        'postfix.kv.relay',
        'postfix.kv.dsn',
        'postfix.kv.delay',
        'postfix.kv.delays',
        'postfix.service',
        'rspamd.action',
        'rspamd.message-id',
        'rspamd.score.value',
        'rspamd.score.threshold',
    ];

    public function init()
    {
        if (!isset($_SESSION['username'])) {
            return;
        }

        $this->rc = rcmail::get_instance();
        $this->load_config();
        $this->add_texts('localization/', true);

        $this->register_task('elasticlogs');
        $this->register_action('index', [$this, 'action_index']);
        $this->register_action('search', [$this, 'action_search']);

        $this->add_hook('startup', [$this, 'startup']);
    }

    public function startup($args)
    {
        if (!$this->rc->output->framed) {
            $this->add_button([
                'command'    => 'elasticlogs',
                'class'      => 'button-elasticlogs',
                'classsel'   => 'button-elasticlogs button-selected',
                'innerclass' => 'button-inner',
                'label'      => 'elasticlogs.task_title',
                'type'       => 'link',
            ], 'taskbar');

            $this->include_script('js/elasticlogs.js');
        }

        $this->include_stylesheet($this->local_skin_path() . '/elasticlogs.css');

        return $args;
    }

    public function action_index()
    {
        $this->rc->output->set_pagetitle($this->gettext('task_title'));
        $this->rc->output->add_handlers([
            'plugin.searchform'    => [$this, 'render_searchform'],
            'plugin.searchresults' => [$this, 'render_searchresults'],
        ]);
        $this->rc->output->send('elasticlogs.index');
    }

    public function action_search()
    {
        $mode = rcube_utils::get_input_string('_mode', rcube_utils::INPUT_POST);

        if ($mode === 'outbound') {
            $this->search_outbound();
        } else {
            $this->rc->output->command('plugin.elasticlogs_search_response', [
                'results' => [],
                'count'   => 0,
            ]);
        }

        $this->rc->output->send();
    }

    private function build_es_client(): \Elastic\Elasticsearch\Client
    {
        $config = $this->rc->config->get('elasticlogs');

        return ClientBuilder::create()
            ->setHosts([$config['elasticsearch_host']])
            ->setBasicAuthentication($config['elasticsearch_username'], $config['elasticsearch_password'])
            ->setSSLVerification($config['elasticsearch_verify_tls'] ?? true)
            ->build();
    }

    private static function hydrate_response(\Elastic\Elasticsearch\Response\Elasticsearch $response): array {
        $response = $response->asArray();
        $keys = array_map(function ($column) { return $column['name']; }, $response['columns']);
        $data = array_map(function ($row) use ($keys) {
            return array_combine($keys, $row);
        }, $response['values']);
        return $data;
    }

    private function search_outbound(): void
    {
        $message_id = trim(rcube_utils::get_input_string('_message_id', rcube_utils::INPUT_POST));
        if ($message_id === '') {
            $this->rc->output->command('plugin.elasticlogs_search_response', [
                'results' => [],
                'count'   => 0,
            ]);
            return;
        }

        $config = $this->rc->config->get('elasticlogs');
        $index = $config['elasticsearch_index'];
        $user_email = $_SESSION['username'];
        try {
            $client = $this->build_es_client();

            // Phase 1: find entries by Message-ID
            $response = static::hydrate_response($client->esql()->query([
                'body'  => [
                    'query' => sprintf(<<<EOQ
FROM %s
| WHERE `postfix.message-id` == "%s"
| SORT @timestamp ASC
EOQ, $index, strtr($message_id, [ '\\' => '', '"' => '' ]))
                ]
            ]));

            if (empty($response)) {
                $this->rc->output->command('plugin.elasticlogs_search_response', [
                    'results' => [],
                    'count'   => 0,
                ]);
                return;
            }

            // Access control: check if the logged-in user is the sender
            $sender_match = false;
            foreach ($response as $hit) {
                $from = $hit['postfix.from'];
                if ($from !== null && strcasecmp($from, $user_email) === 0) {
                    $sender_match = true;
                    break;
                }
            }

            if (!$sender_match) {
                $this->rc->output->command('plugin.elasticlogs_search_response', [
                    'results' => [],
                    'count'   => 0,
                ]);
                return;
            }

            // Phase 2: Expand by referenced (hostname, queueid) pairs
            $pairs = [];
            foreach ($response as $hit) {
                $hostname = $hit['host.hostname'];
                $queueid = $hit['postfix.queueid'];
                if ($hostname !== null && $queueid !== null) {
                    $key = $hostname . '|' . $queueid;
                    $pairs[$key] = ['hostname' => $hostname, 'queueid' => $queueid];
                }
            }
            if (!empty($pairs)) {
                $response = static::hydrate_response($client->esql()->query([
                    'body'  => [
                        'query' => sprintf(<<<EOQ
FROM %s
| WHERE %s
| SORT @timestamp ASC
EOQ, $index, implode(
                                ' OR ', 
                                array_merge(...[
                                    [ sprintf("(`postfix.message-id` == \"%s\")", strtr($message_id, [ '\\' => '', '"' => '' ])) ],
                                    array_map(function ($pair) {
                                        return sprintf("(postfix.queueid == \"%s\" AND host.hostname == \"%s\")", $pair['queueid'], $pair['hostname']);
                                    }, array_values($pairs))
                                ])))
                            ]
                        ]));
            }

            $this->rc->output->command('plugin.elasticlogs_search_response', [
                'results' => $response,
                'count'   => count($response),
            ]);
        } catch (\Exception $e) {
            rcube::raise_error($e, true, false);
            $this->rc->output->command('display_message', $this->gettext('es_query_error'), 'error');
            $this->rc->output->command('plugin.elasticlogs_search_response', [
                'results' => [],
                'count'   => 0,
            ]);
        }
    }

    public function render_searchform(array $attrib): string
    {
        $attrib['id'] = $attrib['id'] ?? 'elasticlogs-searchform';

        $mode_outbound = html::label(
            ['class' => 'elasticlogs-mode-label'],
            html::tag('input', [
                'type'    => 'radio',
                'name'    => 'search_mode',
                'value'   => 'outbound',
                'checked' => true,
            ]) . ' ' . $this->gettext('search_outbound')
        );

        $mode_inbound = html::label(
            ['class' => 'elasticlogs-mode-label'],
            html::tag('input', [
                'type'  => 'radio',
                'name'  => 'search_mode',
                'value' => 'inbound',
            ]) . ' ' . $this->gettext('search_inbound')
        );

        $mode_selector = html::div(
            ['class' => 'elasticlogs-mode-selector'],
            $mode_outbound . $mode_inbound
        );

        $outbound_fields = html::div(
            ['id' => 'elasticlogs-outbound-fields', 'class' => 'elasticlogs-fields'],
            html::label(['for' => 'elasticlogs-message-id'], $this->gettext('message_id'))
            . html::tag('input', [
                'type' => 'text',
                'id'   => 'elasticlogs-message-id',
                'name' => 'message_id',
                'class' => 'form-control',
                'placeholder' => 'e.g. abc123@mail.example.com',
            ])
        );

        $inbound_fields = html::div(
            ['id' => 'elasticlogs-inbound-fields', 'class' => 'elasticlogs-fields', 'style' => 'display:none'],
            html::label(['for' => 'elasticlogs-sender'], $this->gettext('sender'))
            . html::tag('input', [
                'type' => 'email',
                'id'   => 'elasticlogs-sender',
                'name' => 'sender',
                'class' => 'form-control',
                'placeholder' => 'sender@example.com',
            ])
            . html::label(['for' => 'elasticlogs-date-from'], $this->gettext('date_from'))
            . html::tag('input', [
                'type' => 'datetime-local',
                'id'   => 'elasticlogs-date-from',
                'name' => 'date_from',
                'class' => 'form-control',
            ])
            . html::label(['for' => 'elasticlogs-date-to'], $this->gettext('date_to'))
            . html::tag('input', [
                'type' => 'datetime-local',
                'id'   => 'elasticlogs-date-to',
                'name' => 'date_to',
                'class' => 'form-control',
            ])
        );

        $submit = html::tag('button', [
            'type'  => 'button',
            'id'    => 'elasticlogs-search-btn',
            'class' => 'btn btn-primary',
        ], $this->gettext('search'));

        return html::div(
            $attrib,
            $mode_selector . $outbound_fields . $inbound_fields
            . html::div(['class' => 'elasticlogs-form-actions'], $submit)
        );
    }

    public function render_searchresults(array $attrib): string
    {
        $attrib['id'] = $attrib['id'] ?? 'elasticlogs-searchresults';

        $no_results = html::div(
            ['id' => 'elasticlogs-no-results', 'class' => 'elasticlogs-notice', 'style' => 'display:none'],
            $this->gettext('no_results')
        );

        $results_list = html::div(
            ['id' => 'elasticlogs-results-list'],
            ''
        );

        return html::div($attrib, $no_results . $results_list);
    }
}
