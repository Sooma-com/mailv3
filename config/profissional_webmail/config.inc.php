<?php
// Development: loaded by config.inc.php when gethostname() is "profissional_webmail",
// the webmail container of the Sooma-com/maildev stack.
$config['db_dsnw'] = 'pgsql://roundcube@profissional_db/roundcube_profissional';
$config['imap_host'] = 'profissional_imap:143';
$config['smtp_host'] = 'profissional_submission:587';
$config['managesieve_host'] = 'profissional_imap:2000';
$config['log_driver'] = 'file';
$config['log_dir'] = '/var/log/roundcube/';
// Plugins that need production services (Nexus, Elastic, SSO directory, CalDAV) are left out
$config['plugins'] = [ 'password', 'reset_password', 'username_login', 'subscriptions_option', 'managesieve', 'sooma_smime', 'sooma' ];
$config['product_name'] = 'Sooma webmail (dev)';
