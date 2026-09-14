<?php
$config['reset_password_directory_driver'] = 'ldap';
$config['reset_password_ldap_host'] = '10.5.2.37';
$config['reset_password_ldap_bind_dn'] = 'cn=Manager,dc=portugalmail,dc=net';
$config['reset_password_ldap_bind_password'] = 'secret';
$config['reset_password_ldap_base_dn'] = 'o=mailpessoal,dc=portugalmail,dc=net';
$config['reset_password_ldap_user_query'] = 'mail=${email}';
$config['reset_password_ldap_payment_active_attribute'] = 'paymentActive';
$config['reset_password_ldap_recovery_email_attribute'] = 'recoveryEmail';
$config['reset_password_ldap_recovery_phone_attribute'] = 'recoveryPhone';
$config['reset_password_code_storage_driver'] = 'redis';
$config['reset_password_redis_host'] = '10.5.2.44';
$config['reset_password_duo'] = [
    'transactional' => 19,
    'message' => 18,
    'auth' => 'clix.pt@sooma.com:webEstObDijRed2'
];