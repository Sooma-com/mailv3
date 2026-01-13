<?php

// Initialize Roundcube application
define('INSTALL_PATH', realpath(dirname(__FILE__) . '/../../') . '/');
require_once INSTALL_PATH . 'program/include/iniset.php';

$rcmail = rcmail::get_instance();

// Set content type for CSS
header('Content-Type: image/png');

// Output the logo image
$logo_path = dirname(__FILE__) . '/img/oa.png';
if (file_exists($logo_path)) {
    readfile($logo_path);
} else {
    // Return a 404 if logo doesn't exist
    http_response_code(404);
    echo 'Logo not found';
}