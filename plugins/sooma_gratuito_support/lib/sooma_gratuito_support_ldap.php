<?php
declare(strict_types=1);

/**
 * Access to the gratuito LDAP directory (JammMailAccount / JammMailAlias entries).
 *
 * Connection settings fall back to the password plugin's password_ldap_* values,
 * which point at the same directory with an account that may write to it.
 */
class sooma_gratuito_support_ldap
{
    private const ACCOUNT_ATTRIBUTES = [
        'mail', 'quota', 'creationTime', 'accountActive', 'delete', 'regIp',
        'recoveryEmail', 'recoveryPhone', 'spammer', 'paymentActive', 'paymentData',
    ];
    private const LDAP_NO_SUCH_ATTRIBUTE = 0x10;

    private rcmail $rc;
    private ?\LDAP\Connection $connection = null;

    public function __construct()
    {
        $this->rc = rcmail::get_instance();
    }

    /**
     * Look up an account by address, following an alias to its maildrop.
     *
     * @return array|null Normalised account, see normalise_account()
     */
    public function find_account(string $email): ?array
    {
        $email = strtolower(trim($email));
        if ($email === '' || !rcube_utils::check_email($email, false)) {
            return null;
        }

        $searched_alias = null;
        $aliases = $this->search('(&(objectClass=JammMailAlias)(mail=%s))', [$email], ['maildrop']);
        if (count($aliases) === 1 && count($aliases[0]['maildrop'] ?? []) === 1) {
            $searched_alias = $email;
            $email = strtolower($aliases[0]['maildrop'][0]);
        }

        $accounts = $this->search('(&(objectClass=JammMailAccount)(mail=%s))', [$email], self::ACCOUNT_ATTRIBUTES);
        if (count($accounts) !== 1) {
            return null;
        }

        $account = $this->normalise_account($accounts[0]);
        $account['searched_alias'] = $searched_alias;
        $account['aliases'] = array_map(
            function ($alias) {
                return $alias['mail'][0] ?? '';
            },
            $this->search('(&(objectClass=JammMailAlias)(maildrop=%s))', [$account['mail']], ['mail'])
        );
        sort($account['aliases']);

        return $account;
    }

    /**
     * Change attributes of an account previously returned by find_account().
     *
     * @param array $changes attribute => value; null removes the attribute,
     *                       booleans are stored as TRUE/FALSE
     *
     * @throws Exception on LDAP errors
     */
    public function modify(array $account, array $changes): void
    {
        $replace = [];
        foreach ($changes as $attribute => $value) {
            if ($value === null) {
                if (!@ldap_mod_del($this->ldap(), $account['dn'], [$attribute => []])
                    && ldap_errno($this->ldap()) !== self::LDAP_NO_SUCH_ATTRIBUTE
                ) {
                    throw new Exception(sprintf('Unable to remove %s: %s', $attribute, ldap_error($this->ldap())));
                }
                continue;
            }
            if (is_bool($value)) {
                $value = $value ? 'TRUE' : 'FALSE';
            }
            $replace[$attribute] = is_array($value) ? array_values($value) : (string) $value;
        }

        if ($replace && !@ldap_mod_replace($this->ldap(), $account['dn'], $replace)) {
            throw new Exception(sprintf('Unable to modify %s: %s', $account['mail'], ldap_error($this->ldap())));
        }
    }

    private function config(string $key, string $fallback_key, $default = null)
    {
        $value = $this->rc->config->get('sooma_gratuito_support_ldap_' . $key);
        if ($value === null || $value === '') {
            $value = $this->rc->config->get($fallback_key, $default);
        }

        return $value;
    }

    private function ldap(): \LDAP\Connection
    {
        if ($this->connection !== null) {
            return $this->connection;
        }

        if (!function_exists('ldap_connect')) {
            throw new Exception('The PHP ldap extension is not available');
        }

        // Own setting is host[:port]; the password plugin keeps the port separately
        $own_host = (string) $this->rc->config->get('sooma_gratuito_support_ldap_host', '');
        $default_port = $own_host === '' ? (int) $this->rc->config->get('password_ldap_port', 389) : 389;
        [$host, $scheme, $port] = rcube_utils::parse_host_uri(
            $own_host !== '' ? $own_host : (string) $this->rc->config->get('password_ldap_host', ''),
            $default_port,
            636
        );
        if (!$host) {
            throw new Exception('LDAP host is not configured');
        }
        $uri = sprintf('%s://%s:%d', $scheme === 'ldaps' ? 'ldaps' : 'ldap', $host, $port);

        $ldap = ldap_connect($uri);
        if (!$ldap) {
            throw new Exception('Unable to connect to ' . $uri);
        }
        ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ldap, LDAP_OPT_NETWORK_TIMEOUT, 5);
        ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);

        if ($this->config('starttls', 'password_ldap_starttls', false) && !@ldap_start_tls($ldap)) {
            throw new Exception('Unable to start TLS on ' . $uri . ': ' . ldap_error($ldap));
        }

        $bind_dn = (string) $this->config('bind_dn', 'password_ldap_adminDN', '');
        $bind_password = (string) $this->config('bind_password', 'password_ldap_adminPW', '');
        if (!@ldap_bind($ldap, $bind_dn, $bind_password)) {
            throw new Exception('Unable to bind to ' . $uri . ': ' . ldap_error($ldap));
        }

        return $this->connection = $ldap;
    }

    /**
     * @param string $filter printf-style filter; arguments are escaped for filter use
     *
     * @return array List of entries, each a lowercase attribute => list of values map plus 'dn'
     */
    private function search(string $filter, array $arguments, array $attributes): array
    {
        $filter = vsprintf($filter, array_map(
            function ($argument) {
                return ldap_escape((string) $argument, '', LDAP_ESCAPE_FILTER);
            },
            $arguments
        ));
        $base_dn = (string) $this->config('base_dn', 'password_ldap_basedn', '');

        $result = @ldap_search($this->ldap(), $base_dn, $filter, $attributes, 0, 100, 10, LDAP_DEREF_NEVER);
        if ($result === false) {
            throw new Exception(sprintf('LDAP search %s failed: %s', $filter, ldap_error($this->ldap())));
        }

        $entries = ldap_get_entries($this->ldap(), $result);
        if ($entries === false) {
            throw new Exception('Unable to read LDAP entries: ' . ldap_error($this->ldap()));
        }

        $list = [];
        for ($i = 0; $i < $entries['count']; $i++) {
            $entry = ['dn' => $entries[$i]['dn']];
            foreach ($entries[$i] as $name => $values) {
                if (is_string($name) && is_array($values)) {
                    unset($values['count']);
                    $entry[$name] = array_values($values);
                }
            }
            $list[] = $entry;
        }

        return $list;
    }

    private function normalise_account(array $entry): array
    {
        $first = function (string $attribute) use ($entry): ?string {
            $value = $entry[strtolower($attribute)][0] ?? null;

            return $value === null || $value === '' ? null : $value;
        };

        $quota = null;
        if (preg_match('/storage=(\d+)/', (string) $first('quota'), $matches)) {
            $quota = (int) $matches[1];
        }

        $creation = null;
        if (ctype_digit((string) $first('creationTime'))) {
            $creation = new DateTimeImmutable('@' . $first('creationTime'));
        }

        $payment_expiry = null;
        if (ctype_digit((string) $first('paymentData'))) {
            $payment_expiry = (int) $first('paymentData');
        }

        return [
            'dn'              => $entry['dn'],
            'mail'            => strtolower((string) $first('mail')),
            'quota_kb'        => $quota,
            'creation_time'   => $creation,
            'registration_ip' => $first('regIp'),
            'active'          => $first('accountActive') === 'TRUE',
            'deleted'         => $first('delete') === 'TRUE',
            'spammer'         => $first('spammer') === 'TRUE',
            'recovery_email'  => $first('recoveryEmail'),
            'recovery_phone'  => $first('recoveryPhone'),
            // null when the attribute is missing: the account was never paid
            'payment_active'  => $first('paymentActive') === null ? null : $first('paymentActive') === 'TRUE',
            'payment_expiry'  => $payment_expiry,
        ];
    }
}
