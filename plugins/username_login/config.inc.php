<?php
$config['username_login'] = [
    'database' => [
        'host' => '10.3.9.3',
        'port' => 5432,
        'dbname' => 'mail_profissional',
        'username' => 'horde',
        'password' => 'dummy',
    ],
    'query' => 'SELECT email FROM novis_username_map WHERE username = LOWER(:username)',
];

