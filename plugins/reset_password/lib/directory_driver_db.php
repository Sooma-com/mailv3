<?php
declare(strict_types=1);

class reset_password_directory_db implements reset_password_directory_driver {
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
    public function retrieve_recovery_contacts(string $username, string $domain): array {
        $result = $this->db_query_row(<<<EOQ
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
        ]);
        if (!$result) return [null, null, true];
        $result = array_values($result);
        $result[] = true;
        return $result;
    }
}