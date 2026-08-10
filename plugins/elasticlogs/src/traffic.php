<?php
class elasticlogs_traffic {

    private $plugin;

    public function __construct(elasticlogs $plugin)
    {
        $this->plugin = $plugin;
    }
    public function gettext(...$args): string
    {
        return $this->plugin->gettext(...$args);
    }

    public function action()
    {
        $this->plugin->rc->output->set_pagetitle($this->plugin->gettext('task_title'));
        $this->plugin->rc->output->add_handlers([
            'plugin.searchform'    => [$this, 'render_searchform'],
            'plugin.searchresults' => [$this, 'render_searchresults'],
        ]);
        $this->plugin->rc->output->send('elasticlogs.traffic');
    }
    private static function hydrate_response(\Elastic\Elasticsearch\Response\Elasticsearch $response): array {
        $response = $response->asArray();
        $keys = array_map(function ($column) { return $column['name']; }, $response['columns']);
        $data = array_map(function ($row) use ($keys) {
            return array_combine($keys, $row);
        }, $response['values']);
        $data = array_map(function ($row) {
            return [
                'timestamp' => $row['@timestamp'],
                'subject' => substr($row['message'], 29),
                'from' => $row['postfix.from'],
                'to' => $row['postfix.kv.to'],
            ];
        }, $data);
        return $data;
    }
    public function action_search()
    {
        $date_from = trim(rcube_utils::get_input_string('_date_from', rcube_utils::INPUT_POST));
        $date_to = trim(rcube_utils::get_input_string('_date_to', rcube_utils::INPUT_POST));
        $df = \DateTime::createFromFormat('Y-m-d\TH:i', $date_from);
        $dt = \DateTime::createFromFormat('Y-m-d\TH:i', $date_to);
        if ($df !== false) {
            $df->modify('-1 hour');
            $date_from = $df->format('Y-m-d\TH:i');
        }
        if ($dt !== false) {
            $dt->modify('-1 hour');
            $date_to = $dt->format('Y-m-d\TH:i');
        }
        $config = $this->plugin->rc->config->get('elasticlogs');
        $index = $config['elasticsearch_index'];
        try {
            $client = $this->plugin->build_es_client();

            $response = static::hydrate_response($client->esql()->query([
                'body' => [
                    'query' => sprintf(<<<EOQ
FROM %s
| WHERE @timestamp >= "%s" AND @timestamp <= "%s"
    AND systemd.unit LIKE "sooma-milter@domain-milter.service"
    AND message LIKE "*Message subject: *"
    AND (postfix.kv.to LIKE "*.oa.pt" OR postfix.kv.to LIKE "*@oa.pt")
| SORT @timestamp ASC
EOQ, $index, elasticlogs::escape_esql_string($date_from), elasticlogs::escape_esql_string($date_to))
                ]
            ]));
            $this->plugin->rc->output->command('plugin.elasticlogs_traffic_response', [
                'results' => $response,
                'count'   => count($response),
            ]);
        } catch (\Exception $e) {
            rcube::raise_error($e, true, false);
            $this->plugin->rc->output->command('display_message', $this->gettext('es_query_error'), 'error');
            $this->plugin->rc->output->command('plugin.elasticlogs_search_response', [
                'results' => [],
                'count'   => 0,
            ]);
        }
    }
    public function render_searchform(array $attrib): string
    {
        $attrib['id'] = $attrib['id'] ?? 'elasticlogs-searchform';
        $attrib['class'] = $attrib['class'] ?? 'formcontent';

        $sender_recipient_fields = html::div(
            ['id' => 'elasticlogs-sender-recipient-fields', 'class' => 'elasticlogs-fields'],
            html::label(['for' => 'elasticlogs-date-from'], $this->gettext('date_from'))
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
            'id'    => 'elasticlogs-traffic-btn',
            'class' => 'btn btn-primary search',
        ], $this->gettext('search'));

        return html::div(
            $attrib,
            $sender_recipient_fields
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

        // $download_btn = html::tag('button', [
        //     'type'  => 'button',
        //     'id'    => 'elasticlogs-download-btn',
        //     'class' => 'btn btn-secondary',
        //     'style' => 'display:none',
        // ], $this->gettext('download'));

        return html::div(
            $attrib,
            $no_results . $results_list
            // . html::div(['class' => 'elasticlogs-results-actions formbuttons'], $download_btn)
        );
    }
}