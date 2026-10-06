<?php
// LDAP directory. When unset, the password plugin's password_ldap_host, _port,
// _starttls, _adminDN, _adminPW and _basedn are used: same directory, same writer.
// $config['sooma_gratuito_support_ldap_host'] = '10.5.2.37:389';
// $config['sooma_gratuito_support_ldap_starttls'] = false;
// $config['sooma_gratuito_support_ldap_bind_dn'] = 'cn=Manager,dc=portugalmail,dc=net';
// $config['sooma_gratuito_support_ldap_bind_password'] = '';
// $config['sooma_gratuito_support_ldap_base_dn'] = 'o=mailpessoal,dc=portugalmail,dc=net';

// IMAP storage usage, read by logging in as <mail><separator><master user>.
// The host defaults to imap_host. Usage shows as unknown without a master user.
// $config['sooma_gratuito_support_imap_host'] = '10.5.2.41:143';
// $config['sooma_gratuito_support_master_separator'] = '*';
// $config['sooma_gratuito_support_master_user'] = 'masteruser';
// $config['sooma_gratuito_support_master_password'] = 'fedhiccipackAx6';

// Support administrators: domain => logins allowed to manage accounts in that domain.
// Being listed for any domain shows the Support task.
$sooma_gratuito_support_admins = [
    'manuel.costa@portugalmail.pt',
    'sergio.carvalho@portugalmail.pt',
    'goncalo.monteiro@portugalmail.pt',
    'ab@aeiou.pt',
    'tiago.reisinho@portugalmail.pt',
    'support@portugalmail.pt',
];
$sooma_gratuito_support_admins_isp = array_merge($sooma_gratuito_support_admins, ['nos.support@clix.pt']);
$config['sooma_gratuito_support_administrators'] = [
    'clix.pt'          => $sooma_gratuito_support_admins_isp,
    'kanguru.pt'       => $sooma_gratuito_support_admins_isp,
    'mail.optimus.pt'  => $sooma_gratuito_support_admins_isp,
    'mail.pt'          => $sooma_gratuito_support_admins_isp,
    'oniduo.pt'        => $sooma_gratuito_support_admins_isp,
    'oninet.pt'        => $sooma_gratuito_support_admins_isp,
    'oninetspeed.pt'   => $sooma_gratuito_support_admins_isp,
    'optimus.clix.pt'  => $sooma_gratuito_support_admins_isp,
    'portugalmail.pt'  => $sooma_gratuito_support_admins,
    'portugalmail.com' => $sooma_gratuito_support_admins,
];
unset($sooma_gratuito_support_admins, $sooma_gratuito_support_admins_isp);

// Duo transactional message used to send a new password by SMS.
// The message template receives the "telephone" and "password" parameters.
// Override per host in config/<host>/sooma_gratuito_support.inc.php.
$config['sooma_gratuito_support_duo'] = [
    'transactional' => 19,
    'message' => 10,
    'auth' => 'clix.pt@sooma.com:webEstObDijRed2',
];
