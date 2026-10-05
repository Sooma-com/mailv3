<?php
$config['db_dsnw'] = 'pgsql://roundcube:dummy@10.5.2.46/roundcube_profissional';
$config['log_driver'] = 'syslog';
$config['imap_host'] = '10.1.1.116:143';
$config['smtp_host'] = '10.1.1.116:587';
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['support_url'] = '';
$config['des_key'] = 'TtPVDYxG8475G1t4tBjjzHbP';
$config['product_name'] = 'Sooma webmail';
$config['identities_level'] = 4;
$config['plugins'] = [ 'xcalendar', 'password', 'reset_password', 'username_login', 'subscriptions_option', 'nexus', 'nexus_storage', 'nexus_registered', 'managesieve', 'sooma_smime', 'elasticlogs', 'sooma_sso', 'sooma'];
$config['language'] = 'pt_PT';
$config['htmleditor'] = 1;
$config['reply_mode'] = 1;
$config['skin'] = 'sooma';
$config['license_key'] = 'RCP-mxmqqE3Fkx6n';
$config['dont_override'] = ['use_subscriptions', 'skin'];
$config['use_subscriptions'] = false;
$config['show_images'] = 2;
$config['sooma_sso_directory_address'] = '10.5.2.46:2000';
$config['xcalendar_show_xcalendar'] = false;
{
    $local_config_host = strtolower(explode(':', $_SERVER['HTTP_HOST'] ?? '', 2)[0]);
    $local_config_file = realpath(__DIR__ . '/' . strtr($local_config_host, [ '..' => '', '"' => '', "'" => '', '\\' => '' ]) . '/config.inc.php');
    if ($local_config_file) include $local_config_file;
    unset($local_config_file, $local_config_host);
}
{
    $local_config_host = gethostname();
    $local_config_file = realpath(__DIR__ . '/' . strtr($local_config_host, [ '..' => '', '"' => '', "'" => '', '\\' => '' ]) . '/config.inc.php');
    if ($local_config_file) include $local_config_file;
    unset($local_config_file, $local_config_host);
}
