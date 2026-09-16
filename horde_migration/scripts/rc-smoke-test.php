<?php
/**
 * Smoke test: boot Roundcube directly on the host (PHP 8.4 here satisfies
 * Roundcube's own >=7.3 requirement, so no container needed).
 *
 * config/config.inc.php ends with a per-vhost override block keyed off
 * $_SERVER['HTTP_HOST'] (config/<host>/config.inc.php). Three such vhost
 * dirs already exist (correio.aeiou.pt, correio.portugalmail.pt,
 * webmail.clix.pt) and all three point db_dsnw at this exact test DB
 * (10.5.2.44/roundcube_gratuito) and trim the plugin list down to the
 * safe subset - this is clearly the intended way to run against the test
 * DB, so we set HTTP_HOST to one of them rather than editing
 * config.inc.php (which points at production) or bypassing it.
 *
 * Important: with HTTP_HOST unset (the CLI default), that override block
 * resolves its own path to itself and include()s config.inc.php into
 * itself recursively forever - this is what an earlier bare
 * `rcmail::get_instance()` run hung on. Setting HTTP_HOST up front avoids
 * that entirely.
 */

define('INSTALL_PATH', '/home/sergio/Projects/Sooma/Profissional/webmail-roundcube/');
chdir(INSTALL_PATH);

$_SERVER['HTTP_HOST'] = 'correio.portugalmail.pt';

require_once INSTALL_PATH . 'program/include/clisetup.php';

echo "DB DSN in effect: " . $rcmail->config->get('db_dsnw') . "\n";
echo "Loaded plugins: " . implode(', ', $rcmail->plugins->loaded_plugins()) . "\n";

$db = $rcmail->get_dbh();
$res = $db->query('SELECT user_id, username, mail_host FROM users ORDER BY user_id');
while ($row = $db->fetch_assoc($res)) {
    echo " - {$row['user_id']}: {$row['username']} @ {$row['mail_host']}\n";
}

$user = rcube_user::query('sergio.carvalho@portugalmail.pt', '10.5.2.41');
echo "Resolved user: " . ($user ? $user->ID : 'NOT FOUND') . "\n";

echo "OK\n";
