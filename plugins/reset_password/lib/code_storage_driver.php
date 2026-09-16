<?php
declare(strict_types=1);

interface reset_password_code_storage_driver {
    public function generate_recovery_code(string $username, string $domain, array $channels): array;
    public function increment_attempt_count(string $username, string $domain): void;
    public function mark_code_used(string $username, string $domain, string $code): void;
}
