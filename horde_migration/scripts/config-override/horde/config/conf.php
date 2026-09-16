<?php
/**
 * Minimal, secret-free Horde global config used ONLY to run read-only
 * export scripts locally against the read-only replica DB.
 *
 * This intentionally does NOT reuse the real production
 * config/horde/config/conf.php (which carries live DB/IMAP/session
 * secrets) - see horde_migration/specs/00-overview.md. It supplies just
 * enough for Horde_Registry::appInit('turba'|'kronolith', array('cli' =>
 * true)) to boot and for the Sql-backed share/prefs/group/perms drivers to
 * connect to the read-only export DB.
 */

$conf['vhosts'] = false;
$conf['debug_level'] = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED;
$conf['max_exec_time'] = 0;
$conf['compress_pages'] = false;
$conf['secret_key'] = 'local-export-only-not-a-real-secret';
$conf['umask'] = 022;
$conf['testdisable'] = true;
$conf['tmpdir'] = '/tmp/horde-export/';
$conf['use_ssl'] = 0;

$conf['session']['name'] = 'horde_export_cli';
$conf['session']['use_only_cookies'] = true;
$conf['session']['cache_limiter'] = 'nocache';
$conf['session']['timeout'] = 14400;
$conf['cookie']['domain'] = '';
$conf['cookie']['path'] = '/';

/* Read-only export DB - see horde_migration/specs/00-overview.md. */
$conf['sql']['persistent'] = false;
$conf['sql']['database'] = 'mail_gratuito';
$conf['sql']['username'] = 'horde';
$conf['sql']['password'] = '';
$conf['sql']['hostspec'] = '10.3.1.132';
$conf['sql']['port'] = 5432;
$conf['sql']['protocol'] = 'tcp';
$conf['sql']['charset'] = 'utf-8';
$conf['sql']['phptype'] = 'pgsql';
$conf['nosql']['phptype'] = false;

$conf['ldap']['useldap'] = false;

$conf['auth']['driver'] = 'Null';
$conf['auth']['checkip'] = false;
$conf['auth']['checkbrowser'] = false;
$conf['auth']['admins'] = array();

$conf['log']['type'] = 'stream';
$conf['log']['name'] = 'php://stderr';
$conf['log']['priority'] = 'NOTICE';
$conf['log']['params'] = array();
$conf['log']['enabled'] = true;
$conf['log_accesskeys'] = false;

$conf['prefs']['maxsize'] = 1048576;
$conf['prefs']['params']['driverconfig'] = 'horde';
$conf['prefs']['driver'] = 'Sql';

$conf['alarms']['params']['driverconfig'] = 'horde';
$conf['alarms']['params']['ttl'] = 300;
$conf['alarms']['driver'] = 'Sql';

$conf['datatree']['driver'] = 'null';

$conf['group']['driverconfig'] = 'horde';
$conf['group']['driver'] = 'Sql';
$conf['group']['cache'] = false;

$conf['perms']['driverconfig'] = 'horde';
$conf['perms']['driver'] = 'Sql';

$conf['share']['world'] = false;
$conf['share']['any_group'] = false;
$conf['share']['hidden'] = false;
$conf['share']['cache'] = false;
$conf['share']['driver'] = 'Sqlng';

$conf['cache']['default_lifetime'] = 0;
$conf['cache']['driver'] = 'Null';
$conf['cachecss'] = false;
$conf['cachejs'] = false;
$conf['cachethemes'] = false;

$conf['lock']['driver'] = 'Null';
$conf['token']['driver'] = 'Null';

$conf['davstorage']['params']['driverconfig'] = 'horde';
$conf['davstorage']['driver'] = 'Sql';

$conf['mailer']['type'] = 'null';

$conf['vfs']['params']['vfsroot'] = '/tmp/horde-export/vfs';
$conf['vfs']['type'] = 'File';

$conf['sessionhandler']['type'] = 'Builtin';

$conf['image']['driver'] = false;
$conf['exif']['driver'] = false;

$conf['problems']['email'] = 'nobody@example.com';
$conf['problems']['maildomain'] = 'example.com';
$conf['problems']['tickets'] = false;
$conf['problems']['attachments'] = false;

$conf['accounts']['driver'] = 'null';
$conf['user']['verify_from_addr'] = false;
$conf['user']['force_view'] = 'dynamic';
$conf['user']['select_view'] = false;

$conf['urlshortener'] = false;
$conf['weather']['provider'] = false;
$conf['imap']['enabled'] = false;
$conf['imsp']['enabled'] = false;
$conf['kolab']['enabled'] = false;

$conf['hashtable']['driver'] = 'Null';
$conf['activesync']['enabled'] = false;

$conf['facebook']['enabled'] = false;
$conf['twitter']['enabled'] = false;
$conf['flickr']['enabled'] = false;
$conf['recaptcha']['enabled'] = false;
$conf['analytics']['enabled'] = false;
$conf['skins']['enabled'] = false;
$conf['dfp']['enabled'] = false;
$conf['netscope']['enabled'] = false;
