<?php
// Development against LIVE production mail: used when the webmail container is reached as
// sooma-mail-live.local (needs the Sooma VPN). IMAP, SMTP and Sieve are the production ones from
// the main config, so reading, moving, deleting and sending here is real.
// The Roundcube database stays local (profissional_db container), never the production one.
$config['db_dsnw'] = 'pgsql://roundcube@profissional_db/roundcube_live';
$config['log_driver'] = 'file';
$config['log_dir'] = '/var/log/roundcube/';
// Left out until 10.5.2.46 (mail_profissional DB and SSO directory) is reachable from the VPN, or
// because they would write to production: username_login, password, reset_password, nexus*,
// sooma_sso. xcalendar needs its tables (restore a dump of roundcube_profissional first).
$config['plugins'] = [ 'subscriptions_option', 'managesieve', 'sooma_smime', 'elasticlogs', 'sooma' ];
$config['product_name'] = 'Sooma webmail (LIVE)';
