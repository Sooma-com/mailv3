<?php
if (! function_exists("array_last")) {
    function array_last(array $array) {
        return $array ? $array[array_key_last($array)] : null;
    }
}
$config['db_dsnw'] = 'pgsql://roundcube:dummy@10.5.2.44/roundcube_gratuito';
$config['imap_host'] = '10.5.2.41:143';
$config['smtp_host'] = '10.5.2.41:587';
$config['smtp_xclient_login'] = true;
$config['smtp_xclient_addr'] = true;

$config['plugins'] = array_diff(
    $config['plugins'], 
    ['reset_password', 'username_login', 'subscriptions_option', 'nexus', 'nexus_storage', 'nexus_registered', 'sooma_smime', 'elasticlogs']
);
$config['product_name'] = 'Xekmail';