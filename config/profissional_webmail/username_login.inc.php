<?php
// Isolated stack: use the maildev database, never production
$config['username_login'] = [
    'database' => [
        'host' => 'profissional_db',
        'port' => 5432,
        'dbname' => 'mail_profissional',
        'username' => 'horde',
        'password' => '',
    ],
    'query' => 'SELECT email FROM novis_username_map WHERE username = LOWER(:username)',
];
