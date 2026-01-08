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
class username_login extends rcube_plugin
{
    public $rc;
    public $_db = null;

    public function init()
    {
        $this->rc = rcmail::get_instance();
        if ($this->rc->task != 'login') return;
        $this->load_config();
        $this->add_hook('authenticate', [$this, 'authenticate']);
    }
    public function db() {
        if ($this->_db === null) {
            $rcmail = rcmail::get_instance();
            $db_config = $rcmail->config->get('username_login')['database'];
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
    public function authenticate($args) {
        if (strpos($args['user'], '@')) return $args;
        $rcmail = rcmail::get_instance();
        $result = $this->db_query_row($rcmail->config->get('username_login')['query'], ['username' => $args['user']]);
        if ($result) $args['user'] = $result['email'];
        return $args;
    }
}