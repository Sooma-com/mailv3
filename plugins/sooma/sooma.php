<?php
/**
 * Reset Password Plugin for Roundcube
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
class sooma extends rcube_plugin
{
    public $rc;
    public $_db = null;

    public function init()
    {
        $this->rc = rcmail::get_instance();
        $this->load_config();
        $this->add_texts('localization/');
        $this->include_stylesheet('css.php');
        $this->add_hook('html_editor', [$this, 'html_editor']);
        $this->add_hook('storage_connect', [$this, 'storage_connect']);
        $this->include_script('js/editor_toolbar.js');

        $this->rc->load_language(null, [], ['list' => 'Lista']);
        $this->configuration_override();
    }

    public function storage_connect($args)
    {
        if (!$this->rc->config->get('sooma_imap_xclient_addr')) {
            return $args;
        }

        $ip = rcube_utils::remote_addr();
        if ($ip === '') {
            return $args;
        }

        foreach (['ident', 'preauth_ident'] as $key) {
            $args[$key] = (array) ($args[$key] ?? []);
            $args[$key]['x-originating-ip'] = $ip;
        }

        return $args;
    }
    public function configuration_override() {
        $override_dirs = [
            realpath(__DIR__ . '/../../config/' . strtolower($_SERVER['HTTP_HOST'] ?? 'nonexistant')),
            realpath(__DIR__ . '/../../config/' . gethostname()),
        ];
        foreach ($override_dirs as $override_dir) {
            if (!$override_dir || !is_dir($override_dir)) continue;
            foreach ($this->rc->plugins->loaded_plugins() as $plugin_name) {
                $override_file = realpath($override_dir . '/' . $plugin_name . '.inc.php');
                if (!$override_file || !is_file($override_file)) continue;
                $plugin = $this->rc->plugins->get_plugin($plugin_name);
                $override_file = explode('/', $override_file);
                $plugin_home = explode('/', $plugin->home);
                while ($override_file[0] === $plugin_home[0]) {
                    array_shift($override_file);
                    array_shift($plugin_home);
                }
                $override_file_relative = sprintf("/%s/%s", 
                    implode('/', array_map(function() { return '..'; }, $plugin_home)),
                    implode('/', $override_file)
                );
                $plugin->load_config($override_file_relative);
            }
        }
    }
    public function html_editor($args)
    {
        $args['extra_plugins'][] = 'fullscreen';
        $args['extra_buttons'][] = 'fullscreen';

        if (!in_array($args['mode'], ['identity', 'response'])) {
            $args['disabled_plugins'] = array_merge($args['disabled_plugins'], [
                'charmap', 'code', 'directionality', 'media', 'searchreplace',
            ]);
        }

        return $args;
    }

    public function db() {
        if ($this->_db === null) {
            $rcmail = rcmail::get_instance();
            $db_config = $rcmail->config->get('sooma_db');
            $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s', 
                $db_config['host'], 
                $db_config['port'], 
                $db_config['dbname']
            );
            $db = new PDO($dsn, $db_config['username'], $db_config['password']);
            $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->_db = $db;
        }
        return $this->_db;
    }
    public function db_exec($query, $params) {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue($key, $value);
        $stmt->execute();
    }

    public function db_query_row($query, $params) {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue($key, $value);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        return $result;
    }
}
