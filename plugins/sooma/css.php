<?php

// Initialize Roundcube application
define('INSTALL_PATH', realpath(dirname(__FILE__) . '/../../') . '/');
require_once INSTALL_PATH . 'program/include/iniset.php';

$rcmail = rcmail::get_instance();

// Set content type for CSS
header('Content-Type: text/css');

// Get current logged in user
$user = $rcmail->user;
if (!$user || !$user->ID || !$user->data || !$user->data['username']) {
    print('/* No user logged in */');
    exit;
}

$username = $user->data['username'];
if (strpos($username, '@') === false) {
    print('/* Username is not an email */');
    exit;
}
$domain = explode('@', $username)[1];
if (preg_match('/\\.oa\\.pt$/', $domain) || preg_match('/sooma\\.com$/', $domain)) {
    print(<<<EOS
:root {
  --color-layout-header-localmenu-background: #0B1313;
  --color-main: #7b2532;
}
/* Test */
EOS);
} else {
    print('/* No customization applied */');
    exit;
}