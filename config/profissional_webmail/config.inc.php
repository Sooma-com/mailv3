<?php
// Development: loaded by config.inc.php when gethostname() is "profissional_webmail",
// the webmail container of the Sooma-com/maildev stack.
// When the container is reached as sooma-mail-live.local, config/sooma-mail-live.local applies
// instead (production mail), so the isolated-stack settings below must not override it.
if (strtolower(explode(':', $_SERVER['HTTP_HOST'] ?? '', 2)[0]) === 'sooma-mail-live.local') return;
$config['db_dsnw'] = 'pgsql://roundcube@profissional_db/roundcube_profissional';
$config['imap_host'] = 'profissional_imap:143';
$config['smtp_host'] = 'profissional_submission:587';
$config['managesieve_host'] = 'profissional_imap:2000';
$config['log_driver'] = 'file';
$config['log_dir'] = '/var/log/roundcube/';
// Plugins that need production services (Nexus, Elastic, SSO directory, CalDAV) are left out
$config['plugins'] = [ 'password', 'reset_password', 'username_login', 'subscriptions_option', 'managesieve', 'sooma_smime', 'sooma' ];
$config['product_name'] = 'Sooma webmail (dev)';
