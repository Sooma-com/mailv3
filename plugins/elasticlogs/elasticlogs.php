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

        if ($mode === 'message-id') {
            $this->search_by_message_id();
        } elseif ($mode === 'sender-recipient') {
            $this->search_by_sender_recipient();
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

    private static function escape_esql_string(string $string): string
    {
        return strtr($string, ['\\' => '', '"' => '']);
    }

    private function search_by_message_id(): void
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
EOQ, $index, static::escape_esql_string($message_id))
                ]
            ]));

            if (empty($response)) {
                $this->rc->output->command('plugin.elasticlogs_search_response', [
                    'results' => [],
                    'count'   => 0,
                ]);
                return;
            }

            $access_granted = false;
            foreach ($response as $hit) {
                $from = $hit['postfix.from'] ?? null;
                $to = $hit['postfix.kv.to'] ?? null;
                if (($from !== null && strcasecmp($from, $user_email) === 0)
                    || ($to !== null && strcasecmp($to, $user_email) === 0)) {
                    $access_granted = true;
                    break;
                }
            }

            $access_granted = true; // TODO Remove this before commit

            if (!$access_granted) {
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
                                    [ sprintf("(`postfix.message-id` == \"%s\")", static::escape_esql_string($message_id)) ],
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

    private function search_by_sender_recipient(): void
    {
        $email = trim(rcube_utils::get_input_string('_sender_recipient', rcube_utils::INPUT_POST));
        $date_from = trim(rcube_utils::get_input_string('_date_from', rcube_utils::INPUT_POST));
        $date_to = trim(rcube_utils::get_input_string('_date_to', rcube_utils::INPUT_POST));

        if ($email === '' || $date_from === '' || $date_to === '') {
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

            $response = static::hydrate_response($client->esql()->query([
                'body' => [
                    'query' => sprintf(<<<EOQ
FROM %s
| WHERE @timestamp >= "%s" AND @timestamp <= "%s"
    AND (postfix.from == "%s" OR postfix.kv.to == "%s")
| SORT @timestamp ASC
EOQ, $index, static::escape_esql_string($date_from), static::escape_esql_string($date_to), static::escape_esql_string($email), static::escape_esql_string($email))
                ]
            ]));

            if (empty($response)) {
                $this->rc->output->command('plugin.elasticlogs_search_response', [
                    'results' => [],
                    'count'   => 0,
                ]);
                return;
            }

            // Access control: keep only entries where the logged-in user is sender or recipient
            $filtered = array_values(array_filter($response, function ($hit) use ($user_email) {
                $from = $hit['postfix.from'] ?? null;
                $to = $hit['postfix.kv.to'] ?? null;
                return true; // TODO Remove this before commit
                return ($from !== null && strcasecmp($from, $user_email) === 0)
                    || ($to !== null && strcasecmp($to, $user_email) === 0);
            }));

            if (empty($filtered)) {
                $this->rc->output->command('plugin.elasticlogs_search_response', [
                    'results' => [],
                    'count'   => 0,
                ]);
                return;
            }

            // Phase 2: expand by (hostname, queueid) pairs
            $pairs = [];
            foreach ($filtered as $hit) {
                $hostname = $hit['host.hostname'] ?? null;
                $queueid = $hit['postfix.queueid'] ?? null;
                if ($hostname !== null && $queueid !== null) {
                    $key = $hostname . '|' . $queueid;
                    $pairs[$key] = ['hostname' => $hostname, 'queueid' => $queueid];
                }
            }

            if (!empty($pairs)) {
                $email_condition = sprintf(
                    "(postfix.from == \"%s\" OR postfix.kv.to == \"%s\")",
                    static::escape_esql_string($email), static::escape_esql_string($email)
                );
                $pair_conditions = array_map(function ($pair) {
                    return sprintf(
                        "(postfix.queueid == \"%s\" AND host.hostname == \"%s\")",
                        $pair['queueid'], $pair['hostname']
                    );
                }, array_values($pairs));

                $where = implode(' OR ', array_merge([$email_condition], $pair_conditions));

                $filtered = static::hydrate_response($client->esql()->query([
                    'body' => [
                        'query' => sprintf(<<<EOQ
FROM %s
| WHERE @timestamp >= "%s" AND @timestamp <= "%s"
    AND (%s)
| SORT @timestamp ASC
EOQ, $index, static::escape_esql_string($date_from), static::escape_esql_string($date_to), $where)
                    ]
                ]));
            }

            $this->rc->output->command('plugin.elasticlogs_search_response', [
                'results' => $filtered,
                'count'   => count($filtered),
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
        $attrib['class'] = $attrib['class'] ?? 'formcontent';

        $mode_message_id = html::label(
            ['class' => 'elasticlogs-mode-label'],
            html::tag('input', [
                'type'  => 'radio',
                'name'  => 'search_mode',
                'value' => 'message-id',
            ]) . ' ' . $this->gettext('search_message_id')
        );

        $mode_sender_recipient = html::label(
            ['class' => 'elasticlogs-mode-label'],
            html::tag('input', [
                'type'    => 'radio',
                'name'    => 'search_mode',
                'value'   => 'sender-recipient',
                'checked' => true,
            ]) . ' ' . $this->gettext('search_sender_recipient')
        );

        $mode_selector = html::div(
            ['class' => 'elasticlogs-mode-selector custom-control-toggle'],
            $mode_message_id . $mode_sender_recipient
        );

        $message_id_fields = html::div(
            ['id' => 'elasticlogs-message-id-fields', 'class' => 'elasticlogs-fields', 'style' => 'display:none'],
            html::label(['for' => 'elasticlogs-message-id'], $this->gettext('message_id'))
            . html::tag('input', [
                'type' => 'text',
                'id'   => 'elasticlogs-message-id',
                'name' => 'message_id',
                'class' => 'form-control',
                'placeholder' => 'e.g. abc123@mail.example.com',
            ])
        );

        $sender_recipient_fields = html::div(
            ['id' => 'elasticlogs-sender-recipient-fields', 'class' => 'elasticlogs-fields'],
            html::label(['for' => 'elasticlogs-sender-recipient'], $this->gettext('sender_recipient'))
            . html::tag('input', [
                'type' => 'email',
                'id'   => 'elasticlogs-sender-recipient',
                'name' => 'sender_recipient',
                'class' => 'form-control',
                'placeholder' => 'user@example.com',
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
            'class' => 'btn btn-primary search',
        ], $this->gettext('search'));

        return html::div(
            $attrib,
            $mode_selector . $message_id_fields . $sender_recipient_fields
            . html::div(['class' => 'elasticlogs-form-actions formbuttons'], $submit)
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

        $download_btn = html::tag('button', [
            'type'  => 'button',
            'id'    => 'elasticlogs-download-btn',
            'class' => 'btn btn-secondary',
            'style' => 'display:none',
        ], $this->gettext('download'));

        return html::div(
            $attrib,
            $no_results . $results_list
            . html::div(['class' => 'elasticlogs-results-actions formbuttons'], $download_btn)
        );
    }
}
