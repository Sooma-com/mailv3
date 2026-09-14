<?php
declare(strict_types=1);

class reset_password_code_storage_driver_redis implements reset_password_code_storage_driver {
    private array $redis_config = [];
    private ?\Redis $redis = null;
    public function __construct() {
        $this->rc = rcmail::get_instance();

        $this->redis_config = [
            'host' => $this->rc->config->get('reset_password_redis_host'),
            'port' => $this->rc->config->get('reset_password_redis_port') ?? 6379,
            'database' => $this->rc->config->get('reset_password_redis_database') ?? 0,
        ];
        if ($this->rc->config->get('reset_password_redis_password') && $this->rc->config->get('reset_password_redis_username')
            && $this->rc->config->get('reset_password_redis_password') != '' && $this->rc->config->get('reset_password_redis_username') != '') {
            $this->redis['auth'] = [
                'username' => $this->rc->config->get('reset_password_redis_username'),
                'password' => $this->rc->config->get('reset_password_redis_password'),
            ];
        }
    }
    public function increment_attempt_count(string $username, string $domain): void {
        $key = sprintf('reset_password:recovery_code:%s@%s', $username, $domain);
        $existing = $this->redis()->get($key);
        if ($existing) {
            $existing = json_decode($existing, true);
            $existing['attempt_count'] += 1;
            $this->redis()->set($key, json_encode($existing));
        }
    }
    public function generate_recovery_code(string $username, string $domain, array $channels): array {
        $key = sprintf('reset_password:recovery_code:%s@%s', $username, $domain);
        $existing = $this->redis()->get($key);
        if ($existing) {
            $existing = json_decode($existing, true);
            if ($channels['email']) $existing['sent_count']['email'] += 1;
            if ($channels['sms']) $existing['sent_count']['sms'] += 1;
            if ($existing['attempt_count'] > 10 || $existing['used']) { // Rotate a code afer 10 attempts or if used previously
                $existing['code'] = sprintf('%06d', random_int(0, 999999));
                $existing['used'] = false;
                $existing['attempt_count'] = 0;
            }
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
        }
        $this->redis()->set($key, json_encode($existing));
        $this->redis()->expire($key, 60 * 60 * 24);
        return $existing;
    }
    public function mark_code_used(string $username, string $domain, string $code): void {
        $key = sprintf('reset_password:recovery_code:%s@%s', $username, $domain);
        $existing = $this->redis()->get($key);
        if ($existing) {
            $existing = json_decode($existing, true);
            $existing['used'] = true;
            $this->redis()->set($key, json_encode($existing));
        }
    }
    protected function redis(): \Redis {
        if ($this->redis === null) {
            $this->redis = new Redis($this->redis_config);
            $this->redis->connect($this->redis_config['host'], $this->redis_config['port']);
            if (isset($this->redis_config['auth'])) {
                $this->redis->auth($this->redis_config['auth']['username'], $this->redis_config['auth']['password']);
            }
        }
        return $this->redis;
    }
}

