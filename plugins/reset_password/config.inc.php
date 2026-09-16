<?php
$config['reset_password_sooma_db'] = [
    'host' => '10.3.9.3',
    'port' => 5432,
    'dbname' => 'mail_profissional',
    'username' => 'horde',
    'password' => 'dummy',
];
$config['reset_password_directory_driver'] = 'db';
$config['reset_password_code_storage_driver'] = 'db';
$config['hostname_custom_recovery_url_map'] = [
    'webmail.oa.pt' => 'https://portal.oa.pt/reporpass'
];
$config['email_domain_custom_recovery_url_map'] = [
    'oa.pt' => 'https://portal.oa.pt/reporpass',
    '_^.*\.oa\.pt$' => 'https://portal.oa.pt/reporpass',
];
$config['reset_password_duo'] = [
    'transactional' => 21,
    'message' => 83,
    'auth' => 'mailprofissional@sooma.com:vgx2ZjiBLMsi6FF',
];