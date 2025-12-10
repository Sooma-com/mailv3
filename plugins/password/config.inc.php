<?php

// Password Plugin options
// -----------------------
// A driver to use for password change. Default: "sql".
// See README file for list of supported driver names.
$config['password_driver'] = 'sooma';
$config['password_strength_driver'] = 'sooma';
$config['password_confirm_current'] = true;
$config['password_minimum_length'] = 8;
$config['password_minimum_score'] = 4;
$config['password_log'] = false;
$config['password_login_exceptions'] = null;
$config['password_hosts'] = null;
$config['password_force_save'] = false;
$config['password_force_new_user'] = false;
$config['password_algorithm'] = 'ssha256';
$config['password_algorithm_options'] = [];
$config['password_algorithm_prefix'] = '{SSHA}';
// Number of rounds for the sha256 and sha512 crypt hashing algorithms.
// Must be at least 1000. If not set, then the number of rounds is left up
// to the crypt() implementation. On glibc this defaults to 5000.
// Be aware, the higher the value, the longer it takes to generate the password hashes.
//$config['password_crypt_rounds'] = 50000;
$config['password_disabled'] = false;
$config['password_username_format'] = '%u';
$config['password_sooma_db'] = [
    'host' => '10.3.9.3',
    'port' => 5432,
    'dbname' => 'mail_profissional',
    'username' => 'horde',
    'password' => 'dummy',
];
