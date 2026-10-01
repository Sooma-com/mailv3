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
    private const SESSION_THEME_DOMAIN = 'sooma_theme_domain';
    private const SESSION_THEME_LOGO = 'sooma_theme_logo';
    private const SESSION_THEME_HIGHLIGHT = 'sooma_theme_highlight';
    private const SESSION_THEME_TOPBAR = 'sooma_theme_topbar';
    private const DIRECTORY_TIMEOUT_SEC = 5;

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
        $this->add_hook('ready', [$this, 'ready']);
        $this->include_script('js/editor_toolbar.js');

        $this->rc->load_language(null, [], ['list' => 'Lista']);
        $this->configuration_override();
    }

    public function ready($args)
    {
        $domain = $this->theme_domain();
        if (($_SESSION[self::SESSION_THEME_DOMAIN] ?? null) === $domain && (!isset($_SERVER['HTTP_CACHE_CONTROL']) || $_SERVER['HTTP_CACHE_CONTROL'] !== 'no-cache')) {
            return $args;
        }

        $theme = $this->directory_theme($domain);
        if ($theme === null) {
            return $args;
        }

        $_SESSION[self::SESSION_THEME_DOMAIN] = $domain;
        $_SESSION[self::SESSION_THEME_LOGO] = $theme['logo'];
        $_SESSION[self::SESSION_THEME_HIGHLIGHT] = $theme['colors']['highlight'];
        $_SESSION[self::SESSION_THEME_TOPBAR] = $theme['colors']['topbar'];

        return $args;
    }
    public function onload()
    {
        $rcmail = rcmail::get_instance();
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
        if (stripos($user_agent, 'mobile') !== false) {
            $rcmail->config->set('skin', 'sooma-mobile', true);
            $rcmail->config->system_skin = 'sooma-mobile';
        }
    }
    public function theme_variables()
    {
        if (isset($_SESSION[self::SESSION_THEME_HIGHLIGHT]) && isset($_SESSION[self::SESSION_THEME_TOPBAR]) && isset($_SESSION[self::SESSION_THEME_LOGO])) {
            return [
                'logo' => $_SESSION[self::SESSION_THEME_LOGO] ?? null,
                'highlight' => $_SESSION[self::SESSION_THEME_HIGHLIGHT] ?? null,
                'topbar' => $_SESSION[self::SESSION_THEME_TOPBAR] ?? null,
            ];
        }
        return null;
    }

    private function theme_domain()
    {
        if (!empty($_SESSION['user_id']) && isset($_SESSION['username']) && is_string($_SESSION['username'])) {
            $at = strrpos($_SESSION['username'], '@');
            if ($at !== false && $at < strlen($_SESSION['username']) - 1) {
                return strtolower(substr($_SESSION['username'], $at + 1));
            }
        }

        $host = $_SERVER['HTTP_HOST'] ?? '';
        if (is_string($host) && $host !== '') {
            $host = parse_url('//' . $host, PHP_URL_HOST);
            if (is_string($host)) {
                $labels = explode('.', strtolower(rtrim($host, '.')));
                if (count($labels) >= 3) {
                    array_shift($labels);
                    return implode('.', $labels);
                }
            }
        }

        return 'undefined';
    }

    private function directory_theme($domain)
    {
        if (!function_exists('curl_init')) {
            $this->log_theme_error('the curl extension is not available');
            return null;
        }

        $address = $this->rc->config->get('sooma_directory_address', '');
        if (!is_string($address) || !preg_match('/^[A-Za-z0-9._-]+(?::\d{1,5})?$/', $address)) {
            $this->log_theme_error('sooma_directory_address is missing or invalid');
            return null;
        }

        $url = 'http://' . $address . '/directory/theme/' . rawurlencode($domain) . '/';
        $ch = curl_init($url);
        if ($ch === false) {
            $this->log_theme_error('failed to initialize GET ' . $url);
            return null;
        }

        curl_setopt_array($ch, [
            CURLOPT_HTTPGET => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_CONNECTTIMEOUT => self::DIRECTORY_TIMEOUT_SEC,
            CURLOPT_TIMEOUT => self::DIRECTORY_TIMEOUT_SEC,
            CURLOPT_HTTPHEADER => ['Accept: application/json'],
        ]);

        $body = curl_exec($ch);
        if ($body === false) {
            $error = curl_error($ch);
            curl_close($ch);
            $this->log_theme_error('GET ' . $url . ' failed: ' . $error);
            return null;
        }

        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($status < 200 || $status >= 300) {
            $this->log_theme_error('GET ' . $url . ' returned HTTP ' . $status);
            return null;
        }

        $response = json_decode($body, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            $this->log_theme_error('GET ' . $url . ' failed to decode JSON: ' . json_last_error_msg());
            return null;
        }

        if (!is_array($response) || ($response['success'] ?? null) !== true) {
            $this->log_theme_error('GET ' . $url . ' returned an unsuccessful response');
            return null;
        }

        $data = $response['data'] ?? null;
        if (
            !is_array($data)
            || !isset($data['logo']) || !is_string($data['logo'])
            || !isset($data['colors']) || !is_array($data['colors'])
            || !isset($data['colors']['highlight']) || !is_string($data['colors']['highlight'])
            || !isset($data['colors']['topbar']) || !is_string($data['colors']['topbar'])
        ) {
            $this->log_theme_error('GET ' . $url . ' returned malformed theme data');
            return null;
        }

        return $data;
    }

    private function log_theme_error($message)
    {
        rcube::raise_error([
            'code' => 600,
            'type' => 'php',
            'message' => 'sooma: directory theme request failed: ' . $message,
        ], true, false);
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
