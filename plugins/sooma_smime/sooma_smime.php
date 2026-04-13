<?php
declare(strict_types=1);
require_once(__DIR__ . "/src/Exception.php");
require_once(__DIR__ . "/src/Certificate.php");
require_once(__DIR__ . "/src/BaseCertificate.php");
require_once(__DIR__ . "/src/DBCertificate.php");
require_once(__DIR__ . "/src/Settings.php");
require_once(__DIR__ . "/src/Compose.php");
require_once(__DIR__ . "/src/Signer.php");
require_once(__DIR__ . "/src/WrappedMessage.php");
require_once(__DIR__ . "/src/Message.php");
/**
 * Sooma S/MIME Plugin for Roundcube
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
class sooma_smime extends rcube_plugin
{
    public $task = 'login|mail|settings';
    public $rc;
    public $config;
    public \PDO|null $_db = null;
    public function init()
    {
        $this->rc = rcmail::get_instance();
        $this->load_config();
        $this->config = $this->rc->config->get('sooma_smime');
        if (!$this->config) {
            return;
        }
        $this->add_texts('localization/', true);
        $this->include_script('js/sooma_smime.js');
        new \Sooma\Smime\Settings($this);
        new \Sooma\Smime\Compose($this);
        new \Sooma\Smime\Signer($this);

        // $this->register_task('elasticlogs');
        // $this->register_action('index', [$this, 'action_index']);
        // $this->register_action('show', [$this, 'action_index']);
        // $this->register_action('search', [$this, 'action_search']);
        // if ($this->rc->task == 'settings') {
        //     $this->add_hook('settings_actions', [$this, 'settings_actions']);
        // } else if ($this->rc->task == 'mail') {
        //     $this->mail_task_handler();
        // }

        // $this->add_hook('startup', [$this, 'startup']);
    }
    public function db() {
        if ($this->_db === null) {
            $db_config = $this->config['db'];
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
    public function db_exec($query, $params): void {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue(is_string($key) ? $key : $key + 1, $value);
        $stmt->execute();
    }

    public function db_query_row($query, $params): array|null {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue(is_string($key) ? $key : $key + 1, $value);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$result) return null;
        return $result;
    }
    public function db_query_all($query, $params): array {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue(is_string($key) ? $key : $key + 1, $value);
        $stmt->execute();
        $result = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) $result[] = $row;
        return $result;
    }
}
