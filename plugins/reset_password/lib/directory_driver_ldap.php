<?php
declare(strict_types=1);

class reset_password_directory_ldap implements reset_password_directory_driver {
    public $rc;
    public $ldap_config = [ ];
    protected $ldap_connection = null;
    public function __construct() {
        $this->rc = rcmail::get_instance();
        $this->ldap_config = [
            'host' => $this->rc->config->get('reset_password_ldap_host'),
            'bind_dn' => $this->rc->config->get('reset_password_ldap_bind_dn'),
            'bind_password' => $this->rc->config->get('reset_password_ldap_bind_password'),
            'base_dn' => $this->rc->config->get('reset_password_ldap_base_dn'),
            'user_query' => $this->rc->config->get('reset_password_ldap_user_query'),
            'payment_active_attribute' => $this->rc->config->get('reset_password_ldap_payment_active_attribute'),
            'recovery_email_attribute' => $this->rc->config->get('reset_password_ldap_recovery_email_attribute'),
            'recovery_phone_attribute' => $this->rc->config->get('reset_password_ldap_recovery_phone_attribute'),
        ];
    }
    protected function ldap(): \LDAP\Connection {
        if ($this->ldap_connection === null) {
            $ldap = \ldap_connect(sprintf("ldap://%s:%s", $this->ldap_config['host'], $this->ldap_config['port'] ?? '389'));
            if (!$ldap) throw new \Exception(sprintf("Unable to connect to ldap://%s:%s", $this->ldap_config['host'], $this->ldap_config['port'] ?? '389'));
            if (!ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3)) throw new \Exception(sprintf('Error setting ldap protocol version: %s', ldap_error($ldap)));
            if (!\ldap_bind($ldap, $this->ldap_config['bind_dn'], $this->ldap_config['bind_password'])) throw new \Exception(sprintf('Unable to bind to ldap: %s', ldap_error($ldap)));
            $this->ldap_connection = $ldap;
        }
        return $this->ldap_connection;
    }
    protected function ldap_search(string $query, array $arguments): array {
        foreach($arguments as $key => $value) {
            $value = strtr($value, [
                "\\" => '', 
                '#' => '',
                '+' => '', 
                '<' => '',
                '>' => '',
                "," => '',
                ";" => '',
                '"' => '',
                "=" => '',
            ]); // Reference: https://cheatsheetseries.owasp.org/cheatsheets/LDAP_Injection_Prevention_Cheat_Sheet.html
            $query = strtr($query, [ sprintf('${%s}', $key) => $value ]);
        }
        $search = \ldap_search(
            $this->ldap(),
            $this->ldap_config['base_dn'],
            $query,
            [],
            0,
            -1,
            -1,
            LDAP_DEREF_NEVER, 
            []
        );
        if ($search === false) throw new \Exception(sprintf("Error executing ldap_search: %s", ldap_error($this->ldap())));
        $entry = \ldap_first_entry($this->ldap(), $search);
        if (!$entry) return [];
        $attributes = \ldap_get_attributes($this->ldap(), $entry);
        if ($attributes === false) throw new \Exception(sprintf("Error getting ldap attributes: %s", ldap_error($this->ldap())));
        $attributes["dn"] = [ \ldap_get_dn($this->ldap(), $entry)];
        return array_filter(
            array_map(
                function($attribute) {
                    if (!is_array($attribute)) return false;
                    foreach(array_keys($attribute) as $key) if ($key != (string) ((int) $key)) unset($attribute[$key]);
                    if (count($attribute) == 1) return $attribute[0];
                    return $attribute;
                }, 
                $attributes
            )
        );
    }
    public function retrieve_recovery_contacts(string $username, string $domain): array {
        $search_result = $this->ldap_search($this->ldap_config['user_query'], [ 'login' => $username, 'domain' => $domain, 'email' => $username . '@' . $domain ]);
        if (empty($search_result)) return [null, null, null];
        return [
            $search_result[$this->ldap_config['recovery_email_attribute']] ?? null,
            $search_result[$this->ldap_config['recovery_phone_attribute']] ?? null,
            ($search_result[$this->ldap_config['payment_active_attribute']] ?? "TRUE") === "TRUE",
        ];
    }
}