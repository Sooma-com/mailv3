<?php
// Isolated stack: use the maildev database, never production
$config['password_sooma_db'] = [
    'host' => 'profissional_db',
    'port' => 5432,
    'dbname' => 'mail_profissional',
    'username' => 'horde',
    'password' => '',
];
