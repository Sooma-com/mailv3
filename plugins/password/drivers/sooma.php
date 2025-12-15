<?php

/**
 * Sooma Password Driver
 *
 * Driver for passwords stored in Sooma Profissional Email service
 *
 * @version 2.1
 * @author Sérgio Carvalho <daf@sooma.com>
 *
 * Copyright (C) Sooma.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see https://www.gnu.org/licenses/.
 */
class rcube_sooma_password
{
    function strength_rules()
    {
        $rcmail = rcmail::get_instance();
        $rules  = [
            $rcmail->gettext('password.mustcontainupperlower'),
            $rcmail->gettext('password.mustcontaindigit'),
            $rcmail->gettext('password.mustcontainnonalpha'),
        ];

        return $rules;
    }

    /**
     * Password strength check
     *
     * @param string $passwd Password
     *
     * @return array Score (1 to 5) and Reason
     */
    function check_strength($passwd)
    {
        $rcmail = rcmail::get_instance();
        $score = 5;
        $reasons = [];
        if (strlen($passwd) < 8) {
            $score -= 2;
        }
        if (!preg_match('_[0-9]_', $passwd)) {
            $score -= 1;
            $reasons[] = $rcmail->gettext('password.mustcontaindigit');
        }
        if (!preg_match('_[a-z]_', $passwd) || !preg_match('_[A-Z]_', $passwd)) {
            $score -= 1;
            $reasons[] = $rcmail->gettext('password.mustcontainupperlower');
        }
        if (!preg_match('_[^0-9A-Za-z]_', $passwd)) {
            $score -= 1;
            $reasons[] = $rcmail->gettext('password.mustcontainnonalpha');
        }
        $reasons = implode("<br>", $reasons);
        if (!empty($reasons)) $reasons = "<br>" . $reasons;

        return [$score < 0 ? 0 : $score, $reasons];
    }
    /**
     * Update current user password
     *
     * @param string $curpass Current password
     * @param string $passwd  New password
     *
     * @return int Result
     */
    function save($curpass, $passwd, $username = null)
    {
        $rcmail = rcmail::get_instance();
        if (!$username) $username = $rcmail->user->get_username();
        $new_password_hash = $this->hash_password($passwd);
        $db_config = $rcmail->config->get('password_sooma_db');
        // Connect to PostgreSQL database
        $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s', 
            $db_config['host'], 
            $db_config['port'], 
            $db_config['dbname']
        );
        
        try {
            $pdo = new PDO($dsn, $db_config['username'], $db_config['password']);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            rcube::write_log('errors', 'Sooma password driver: Database connection failed: ' . $e->getMessage());
            return PASSWORD_CONNECT_ERROR;
        }

        try {
            $stmt = $pdo->prepare("SELECT id FROM profissional_emails WHERE email = :email AND type = 'u'");
            $stmt->bindParam(':email', $username);
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            $email_id = $result ? $result['id'] : null;
        } catch (PDOException $e) {
            rcube::write_log('errors', 'Sooma password driver: Query failed: ' . $e->getMessage());
            return PASSWORD_ERROR;
        }
        if (!$email_id) {
            rcube::write_log('errors', 'Sooma password driver: Email account not found for user: ' . $username);
            return PASSWORD_ERROR;
        }

        try {
            $stmt = $pdo->prepare("SELECT password FROM profissional_email_users WHERE email_id = :email_id");
            $stmt->bindParam(':email_id', $email_id);
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            $old_password_hash = $result ? $result['password'] : null;
        } catch (PDOException $e) {
            rcube::write_log('errors', 'Sooma password driver: Query failed: ' . $e->getMessage());
            return PASSWORD_ERROR;
        }
        if (!$old_password_hash) {
            rcube::write_log('errors', 'Sooma password driver: Email account not found for user: ' . $username);
            return PASSWORD_ERROR;
        }

        try {
            $stmt = $pdo->prepare("INSERT INTO profissional_email_user_credential(email_id, type, hash, name) VALUES (:email_id, 'historical', :hash, :name)");
            $stmt->bindParam(':email_id', $email_id);
            $stmt->bindParam(':hash', $old_password_hash);
            $stmt->bindParam(':name', sprintf($rcmail->gettext('password.historicpasswordchange'), date('c')));
            $stmt->execute();
        } catch (PDOException $e) {
            rcube::write_log('errors', 'Sooma password driver: Query failed: ' . $e->getMessage());
            return PASSWORD_ERROR;
        }

        try {
            $stmt = $pdo->prepare("UPDATE profissional_email_users SET password = :password WHERE email_id = :email_id");
            $stmt->bindParam(':email_id', $email_id);
            $stmt->bindParam(':password', $new_password_hash);
            $stmt->execute();
        } catch (PDOException $e) {
            rcube::write_log('errors', 'Sooma password driver: Query failed: ' . $e->getMessage());
            return PASSWORD_ERROR;
        }

        return PASSWORD_SUCCESS;
    }
    function hash_password($clear_password) {
        $salt = '';
        for ($i=1; $i<=10; $i++) $salt .= substr('0123456789abcdef', rand(0,15), 1);
        return sprintf('{SSHA}%s', base64_encode(pack("H*", sha1($clear_password . $salt)) . $salt));
    }
    /**
     * Parse DSN string and replace host variables
     *
     * @param string $dsn DSN string
     *
     * @return string DSN string
     */
    protected static function parse_dsn($dsn)
    {
        if (strpos($dsn, '%')) {
            // parse DSN and replace variables in hostname
            $parsed = rcube_db::parse_dsn($dsn);
            $host   = rcube_utils::parse_host($parsed['hostspec']);

            // build back the DSN string
            if ($host != $parsed['hostspec']) {
                $dsn = str_replace('@' . $parsed['hostspec'], '@' . $host, $dsn);
            }
        }

        return $dsn;
    }
}
