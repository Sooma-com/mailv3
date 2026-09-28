<?php

// Initialize Roundcube application
define('INSTALL_PATH', realpath(dirname(__FILE__) . '/../../') . '/');
require_once INSTALL_PATH . 'program/include/iniset.php';

$rcmail = rcmail::get_instance();
$session_theme = $rcmail->plugins->get_plugin('sooma')->theme_variables();
if ($session_theme && isset($session_theme['logo']) && str_starts_with($session_theme['logo'], 'data:')) {
    $mime_type = explode(':', explode(';', $session_theme['logo'])[0], 2)[1];
    if ($mime_type) {
        $encoding = explode(',', explode(';',$session_theme['logo'])[1])[0];
        $data = base64_decode(explode(',', $session_theme['logo'])[1]);
        if ($encoding && $mime_type) {
            header('Content-Type: ' . $mime_type);
            echo $data;
            exit;
        }
    }
}
header('Content-Type: image/png');
if ($rcmail->config->get('sooma_skin') 
    && $rcmail->config->get('sooma_skin')['tag']
    && file_exists(dirname(__FILE__) . '/img/logo_' . $rcmail->config->get('sooma_skin')['tag'] . '.png')
) {
    readfile(dirname(__FILE__) . '/img/logo_' . $rcmail->config->get('sooma_skin')['tag'] . '.png');
    exit;
}

// Output the logo image
$logo_path = dirname(__FILE__) . '/img/oa.png';
if (file_exists($logo_path)) {
    readfile($logo_path);
} else {
    // Return a 404 if logo doesn't exist
    http_response_code(404);
    echo 'Logo not found';
}