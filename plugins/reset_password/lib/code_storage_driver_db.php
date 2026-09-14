<?php
declare(strict_types=1);

class reset_password_code_storage_driver_db implements reset_password_code_storage_driver {
    public $rc;
    private $_db = null;
    public function __construct() {
        $this->rc = rcmail::get_instance();
    }
    private function db() {
        if ($this->_db === null) {
            $db_config = $this->rc->config->get('reset_password_sooma_db');
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
    protected function retrieve_existing_code(string $username, string $domain): array {
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
            return json_decode($existing, true);
        }
        return null;
    }
    public function generate_recovery_code(string $username, string $domain, array $channels): array {
        $existing = $this->retrieve_existing_code($username, $domain);
        if ($existing) {
            if ($channels['email']) $existing['sent_count']['email'] += 1;
            if ($channels['sms']) $existing['sent_count']['sms'] += 1;
            if ($existing['attempt_count'] > 10 || $existing['used']) { // Rotate a code afer 10 attempts or if used previously
                $existing['code'] = sprintf('%06d', random_int(0, 999999));
                $existing['used'] = false;
                $existing['attempt_count'] = 0;
            }
            $this->db_exec(<<<EOQ
UPDATE profissional_email_user_credential
SET
 hash = :hash,
 last_update = NOW()
WHERE
 type = 'recovery_code'
 AND email_id = (
  SELECT profissional_emails.id
  FROM profissional_emails
       JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent
  WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u'
 ),
EOQ,
                [
                    ':user' => $username,
                    ':domain' => $domain,
                    ':hash' => json_encode($existing),
                ]
            );
        } else {
            $existing = [
                'code' => sprintf('%06d', random_int(0, 999999)),
                'sent_count' => [
                    'email' => $channels['email'] ? 1 : 0,
                    'sms' => $channels['sms'] ? 1 : 0,
                ],
                'attempt_count' => 0,
                'used' => false
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
                    ':hash' => json_encode($existing),
                ]
            );
        }
    }
    public function increment_attempt_count(string $username, string $domain): void {
        $existing = $this->retrieve_existing_code($username, $domain);
        if ($existing) {
            $existing['attempt_count'] += 1;
            $this->db_exec(<<<EOQ
UPDATE profissional_email_user_credential
SET
 hash = :hash
WHERE
 type = 'recovery_code'
 AND email_id = (
  SELECT profissional_emails.id
  FROM profissional_emails
       JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent
  WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u'
 ),
EOQ,
                [
                    ':user' => $username,
                    ':domain' => $domain,
                    ':hash' => json_encode($existing),
                ]
            );
        }
    }
    public function mark_code_used(string $username, string $domain, string $code): void {
        $existing = $this->retrieve_existing_code($username, $domain);
        if ($existing) {
            $existing['used'] = true;
            $this->db_exec(<<<EOQ
UPDATE profissional_email_user_credential
SET
 hash = :hash
WHERE
 type = 'recovery_code'
 AND email_id = (
  SELECT profissional_emails.id
  FROM profissional_emails
       JOIN profissional_domains ON profissional_domains.id = profissional_emails.parent
  WHERE (profissional_emails.username, profissional_domains.name) = (LOWER(:user), LOWER(:domain)) AND type = 'u'
 ),
EOQ,
                [
                    ':user' => $username,
                    ':domain' => $domain,
                    ':hash' => json_encode($existing),
                ]
            );
        }
    }
}

