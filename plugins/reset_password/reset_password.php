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
class reset_password extends rcube_plugin
{
    public $rc;
    public $_db = null;

    public function init()
    {
        $this->rc = rcmail::get_instance();
        if ($this->rc->task != 'login') return;
        $this->load_config();
        $this->add_texts('localization/');
        $this->include_script('js/reset_password.js');
        $this->add_hook('startup', [$this, 'startup']);
        $this->add_hook('render_page', [$this, 'add_labels']);
    }

    public function add_labels($args)
    {
        $this->rc->output->add_label('reset_password.forgot_password');
        $this->rc->output->add_label('reset_password.email');
        $this->rc->output->add_label('reset_password.email_placeholder');
        $this->rc->output->add_label('reset_password.recover_password');
        $this->rc->output->add_label('reset_password.confirm_recovery_email');
        $this->rc->output->add_label('reset_password.confirm_recovery_phone');
        $this->rc->output->add_label('reset_password.recovery_code');
        $this->rc->output->add_label('reset_password.password');
        $this->rc->output->add_label('reset_password.password_confirm');
        $this->rc->output->add_label('reset_password.change_password');
        $this->rc->output->add_label('reset_password.recovery_code_instructions');
        $this->rc->output->add_label('reset_password.password_restriction_confirmation');
        $this->rc->output->add_label('reset_password.password_restriction_length');
        $this->rc->output->add_label('reset_password.password_restriction_case');
        $this->rc->output->add_label('reset_password.password_restriction_digit');
        $this->rc->output->add_label('reset_password.password_restriction_nonalpha');
        $this->rc->output->add_label('reset_password.password_changed');
        $this->rc->output->add_label('reset_password.return_to_login');
    }

    public function startup($args) {
        switch ($this->rc->action) {
            case 'plugin.password_recovery_start':
                $this->password_recovery_start($args);
                exit;
                break;
            case 'plugin.password_recovery_confirm_contact':
                $this->password_recovery_confirm_contact($args);
                exit;
                break;
            case 'plugin.password_recovery_change_password':
                $this->password_recovery_change_password($args);
                exit;
                break;
        }
    }

    public function ajax_error($message) {
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => $message]);
        exit;
    }

    public function ajax_success($data) {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'data' => $data]);
        exit;
    }

    public function db() {
        if ($this->_db === null) {
            $rcmail = rcmail::get_instance();
            $db_config = $rcmail->config->get('reset_password_sooma_db');
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
    public function retrieve_recovery_contacts($username, $domain) {
        return array_values($this->db_query_row(<<<EOQ
SELECT
 email_credential.hash AS recovery_email,
 phone_credential.hash AS recovery_phone
FROM
 profissional_emails
 JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent
 LEFT JOIN profissional_email_user_credential AS email_credential ON (email_credential.email_id, email_credential.type) = (profissional_emails.id, 'recovery_email')
 LEFT JOIN profissional_email_user_credential AS phone_credential ON (phone_credential.email_id, phone_credential.type) = (profissional_emails.id, 'recovery_phone')
WHERE
 (profissional_emails.username, profissional_domains.name, profissional_emails.type) = (LOWER(:user), LOWER(:domain), 'u')
EOQ,
            [
                ':user' => $username,
                ':domain' => $domain,
        ]));
    }
    public function password_recovery_start($args)
    {
        $params = rcube_utils::request2param(rcube_utils::INPUT_POST);
        if (!isset($params['user'])) $this->ajax_error('User param is required');
        $user = explode('@', $params['user']);
        if (count($user) !== 2) $this->ajax_error('Invalid user format');
        $username = $user[0];
        $domain = $user[1];
        list($recovery_email, $recovery_phone) = $this->retrieve_recovery_contacts($username, $domain);
        if (!$recovery_email && !$recovery_phone) $this->ajax_error('Account does not exist or has no recovery contacts');
        $result = [
            'user' => $params['user'],
        ];
        if ($recovery_email) {
            $result['recovery_email_hint'] = $recovery_email;
            for ($i=2; $i < strlen($result['recovery_email_hint']) - 2; $i++) if (false === strpos(substr($result['recovery_email_hint'], $i-2, 5), "@")) $result['recovery_email_hint'][$i] = "*";
        }
        if ($recovery_phone) {
            $result['recovery_phone_hint'] = $recovery_phone;
            for ($i=1; $i < strlen($result['recovery_phone_hint']) - 2; $i++) $result['recovery_phone_hint'][$i] = "*";
        }
        $this->ajax_success($result);
    }
    public function generate_recovery_code($username, $domain) {
        $this->db_exec(<<<EOQ
DELETE FROM profissional_email_user_credential WHERE type = 'recovery_code' AND last_update < NOW() - INTERVAL '1 day' AND email_id = (
 SELECT profissional_emails.id FROM 
  profissional_emails 
  JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent
  WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u')
EOQ,
            [
                ':user' => $username,
                ':domain' => $domain,
            ]
        );
        $existing = $this->db_query_row(<<<EOQ
SELECT hash FROM profissional_email_user_credential WHERE type = 'recovery_code' AND email_id = (
 SELECT profissional_emails.id FROM 
  profissional_emails 
  JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent
  WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u')
EOQ,
            [
                ':user' => $username,
                ':domain' => $domain,
            ]
        );
        if ($existing) {
            $existing = json_decode($existing['hash'], true);
        }
        if (!$existing) {
            $new_code = [
                'sent_count' => 0,
                'attempt_count' => 0,
                'code' => sprintf('%06d', random_int(0, 999999)),
            ];
            $this->db_exec(<<<EOQ
INSERT INTO profissional_email_user_credential (email_id, type, hash, name) VALUES (
 (SELECT profissional_emails.id FROM profissional_emails JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u'),
 'recovery_code',
 :hash,
 'Password recovery code'
 )
EOQ,
                [
                    ':user' => $username,
                    ':domain' => $domain,
                    ':hash' => json_encode($new_code),
                ]
            );
            $existing = $new_code;
        }
        return $existing;
    }
    public function password_recovery_confirm_contact($args) {
        $params = rcube_utils::request2param(rcube_utils::INPUT_POST);
        foreach (['user', 'recovery_email', 'recovery_phone'] as $key) if (!isset($params[$key])) $this->ajax_error(sprintf('%s param is required', $key));
        foreach (['recovery_email', 'recovery_phone'] as $key) if (empty($params[$key])) unset($params[$key]);
        if (!isset($params['recovery_email']) && !isset($params['recovery_phone'])) $this->ajax_error('At least one recovery contact is required');
        $user = explode('@', $params['user']);
        if (count($user) !== 2) $this->ajax_error('Invalid user format');
        $username = $user[0];
        $domain = $user[1];
        list($recovery_email, $recovery_phone) = $this->retrieve_recovery_contacts($username, $domain);
        if (!$recovery_email && !$recovery_phone) $this->ajax_error('Account does not exist or has no recovery contacts');
        if (isset($params['recovery_email']) && $params['recovery_email'] !== $recovery_email) $this->ajax_error('Invalid recovery email');
        if (isset($params['recovery_phone']) && $params['recovery_phone'] !== $recovery_phone) $this->ajax_error('Invalid recovery phone');
        if (!isset($params['recovery_email'])) $recovery_email = null;
        if (!isset($params['recovery_phone'])) $recovery_phone = null;
        $recovery_code = $this->generate_recovery_code($username, $domain);
        if ($recovery_code['sent_count'] >= 2 && $recovery_phone) $recovery_phone = null;
        if ($recovery_phone) {
            $recovery_code['sent_count'] += 1;
            $this->db_exec(<<<EOQ
UPDATE profissional_email_user_credential SET hash = :hash WHERE type = 'recovery_code' AND email_id = 
 (SELECT profissional_emails.id FROM profissional_emails JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u')
EOQ,
                [
                    ':user' => $username,
                    ':domain' => $domain,
                    ':hash' => json_encode($recovery_code),
                ]
            );
        }
        $this->send_recovery_code($recovery_code['code'], $recovery_email, $recovery_phone, $params['user']);
        $this->ajax_success(['user' => $params['user']]);
    }
    public function send_recovery_code($code, $recovery_email, $recovery_phone, $email) {
        $client_id = $this->db_query_row(<<<EOQ
SELECT profissional_domains.parent AS client_id FROM profissional_domains WHERE name = LOWER(:domain)
EOQ,
            [
                ':domain' => explode('@', $email)[1],
            ]
        );
        if (!$client_id) throw new Exception('Client not found');
        $client_id = $client_id['client_id'];
        $duo_args = [
            'url' => 'https://app.duo.pt/transactional/21/message/83/send?',
            'auth' => 'mailprofissional@sooma.com:vgx2ZjiBLMsi6FF'
        ];
        if ($client_id == 5661) { // Ordem dos Advogados 
            // TODO: Setup OA in Duo and redefine $duo_args
        }
        $url_args = [
            'code' => $code,
            'recovered_mail' => $email,
        ];
        if ($recovery_email) $url_args['email'] = $recovery_email;
        if ($recovery_phone) $url_args['telephone'] = $recovery_phone;
        $duo_args['url'] .= http_build_query($url_args);
        $ch = curl_init($duo_args['url']);
        curl_setopt($ch, CURLOPT_USERPWD, $duo_args['auth']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Accept: application/json',
        ]);
        $result = curl_exec($ch);
        curl_close($ch);
    }
    public function password_recovery_change_password($args) {
        $params = rcube_utils::request2param(rcube_utils::INPUT_POST);
        foreach (['user', 'code', 'password', 'password_confirm'] as $key) if (!isset($params[$key])) $this->ajax_error(sprintf('%s param is required', $key));
        $user = explode('@', $params['user']);
        if (count($user) !== 2) $this->ajax_error('Invalid user format');
        $username = $user[0];
        $domain = $user[1];
        $recovery_code = $this->generate_recovery_code($username, $domain);
        if ($recovery_code['attempt_count'] >= 9) $this->ajax_error('Invalid recovery code');
        if ($recovery_code['code'] !== $params['code']) {
            $recovery_code['attempt_count'] += 1;
            $this->db_exec(<<<EOQ
UPDATE profissional_email_user_credential SET hash = :hash WHERE type = 'recovery_code' AND email_id = 
 (SELECT profissional_emails.id FROM profissional_emails JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u')
EOQ,
                [
                    ':user' => $username,
                    ':domain' => $domain,
                    ':hash' => json_encode($recovery_code),
                ]
            );
            $this->ajax_error('Invalid recovery code');
        }
        if (!rcube::get_instance()->plugins->get_plugin('password')) {
            $this->ajax_error('Password plugin is not installed');
        }
        // The password plugin does not expose a save method. We'll basically reproduce 
        // its driver loading logic here, and then use the driver to change the password.
        $password_plugin_driver = rcube::get_instance()->config->get('password_driver', 'sql');
        $password_plugin_driver_file = RCUBE_PLUGINS_DIR . 'password/drivers/' . $password_plugin_driver . '.php';
        $password_plugin_driver_class = 'rcube_' . $password_plugin_driver . '_password';
        if (!file_exists($password_plugin_driver_file)) $this->ajax_error('Password plugin driver file not found');
        include_once $password_plugin_driver_file;
        rcube::get_instance()->plugins->get_plugin('password')->add_texts('../password/localization/');
        if (!class_exists($password_plugin_driver_class)) $this->ajax_error('Password plugin driver class not found');
        if (!method_exists($password_plugin_driver_class, 'save')) $this->ajax_error('Password plugin driver class does not have a save method');
        if (!method_exists($password_plugin_driver_class, 'check_strength')) $this->ajax_error('Password plugin driver class does not have a check_strength method');
        $password_plugin_driver_instance = new $password_plugin_driver_class();
        $password_plugin_driver_minimum_score = rcube::get_instance()->config->get('password_minimum_score');
        if ($params['password'] !== $params['password_confirm']) $this->ajax_error('Password and password confirmation do not match');
        if ($password_plugin_driver_instance->check_strength($params['password'])[0] < $password_plugin_driver_minimum_score) $this->ajax_error('Password is too weak');
        $password_plugin_driver_instance->save($params['password'], $params['password_confirm'], $params['user']);
        $this->db_exec(<<<EOQ
DELETE FROM profissional_email_user_credential WHERE type = 'recovery_code' AND email_id = 
 (SELECT profissional_emails.id FROM profissional_emails JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u')
EOQ,
            [
                ':user' => $username,
                ':domain' => $domain,
            ]
        );
        $this->ajax_success(true);
    }
}
