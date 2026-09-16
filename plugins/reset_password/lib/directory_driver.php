<?php
declare(strict_types=1);

interface reset_password_directory_driver {
    public function retrieve_recovery_contacts(string $username, string $domain): array;
}