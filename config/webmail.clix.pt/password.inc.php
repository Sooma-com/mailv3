<?php
$config['password_driver'] = 'ldap';
$config['password_ldap_host'] = '10.5.2.37';
$config['password_ldap_port'] = '389';
$config['password_ldap_starttls'] = false;
$config['password_ldap_version'] = '3';
$config['password_ldap_basedn'] = 'o=mailpessoal,dc=portugalmail,dc=net';
$config['password_ldap_method'] = 'admin';
$config['password_ldap_adminDN'] = "cn=Manager,dc=portugalmail,dc=net";
$config['password_ldap_adminPW'] = "secret";
$config['password_ldap_userDN_mask'] = 'mail=%login,jvd=%domain,o=mailpessoal,dc=portugalmail,dc=net';
$config['password_ldap_encodage'] = 'sha256-crypt';
$config['password_ldap_pwattr'] = 'clearPassword';
$config['password_ldap_force_replace'] = true;
$config['password_ldap_lchattr'] = '';
$config['password_ldap_samba_pwattr'] = '';
$config['password_ldap_samba_lchattr'] = '';