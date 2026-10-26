<?php
/**
 * Import one mailbox's exported Horde default identity (produced by
 * export-signature.php: identity.json in a directory) into the Roundcube
 * user's default identity, using Roundcube's own APIs (rcube_user::
 * update_identity(), the settings identity-save HTML washer) rather than
 * hand-writing SQL.
 *
 * Usage: import-signature.php <export-dir> [--user USERNAME]
 *            [--mail-host HOST] [--vhost HOST] [--force] [--dry-run]
 *
 *   <export-dir>   Directory produced by export-signature.php, e.g.
 *                  horde_migration/export-output/sergio.carvalho@sooma.com
 *   --user         Roundcube username (default: basename of <export-dir>)
 *   --mail-host    Roundcube users.mail_host to resolve/create the account
 *                  under (default: 10.5.2.48, the profissional IMAP host)
 *   --vhost        HTTP_HOST to boot Roundcube's config as (default:
 *                  localhost, which has no config/<host>/ override, so the
 *                  base profissional config and roundcube_profissional DB
 *                  apply; pass e.g. correio.portugalmail.pt for gratuito)
 *   --force        Overwrite a name/signature already set in Roundcube.
 *                  By default only empty fields are filled, so a signature
 *                  the user already set up in Roundcube is never clobbered
 *                  and re-runs are no-ops.
 *   --dry-run      Report what would change without writing anything.
 *
 * Mapping (Horde identity -> Roundcube identities row):
 *   fullname       -> name
 *   signature_html -> signature, html_signature = 1   (if non-empty)
 *   signature      -> signature, html_signature = 0   (otherwise)
 * Roundcube keeps a single signature per identity, either HTML or plain
 * text, so the HTML one wins when both exist - Roundcube derives the plain
 * text version itself when composing in plain text.
 */

define('INSTALL_PATH', '/home/sergio/Projects/Sooma/Profissional/webmail-roundcube/');

function log_line($msg)
{
    fwrite(STDERR, "[import] $msg\n");
}

// ---- CLI args ---------------------------------------------------------

$args = $argv;
array_shift($args);
$exportDir = array_shift($args);

if (!$exportDir || !is_file("$exportDir/identity.json")) {
    fwrite(STDERR, "Usage: import-signature.php <export-dir> [--user USERNAME] [--mail-host HOST] [--vhost HOST] [--force] [--dry-run]\n");
    exit(1);
}
$exportDir = realpath($exportDir);
$username = basename($exportDir);
$mailHost = '10.5.2.48';
$vhost = 'localhost';
$force = false;
$dryRun = false;
for ($i = 0; $i < count($args); $i++) {
    if ($args[$i] === '--user') {
        $username = $args[++$i];
    } elseif ($args[$i] === '--mail-host') {
        $mailHost = $args[++$i];
    } elseif ($args[$i] === '--vhost') {
        $vhost = $args[++$i];
    } elseif ($args[$i] === '--force') {
        $force = true;
    } elseif ($args[$i] === '--dry-run') {
        $dryRun = true;
    }
}

// config/config.inc.php ends in a per-vhost override block keyed off
// HTTP_HOST; with HTTP_HOST unset (plain CLI) that block resolves its own
// path back to itself and recurses forever - see import-mailbox.php.
$_SERVER['HTTP_HOST'] = $vhost;

chdir(INSTALL_PATH);

require_once INSTALL_PATH . 'program/include/clisetup.php';

$identity = json_decode(file_get_contents("$exportDir/identity.json"), true);
if (!is_array($identity)) {
    fwrite(STDERR, "Cannot parse $exportDir/identity.json: " . json_last_error_msg() . "\n");
    exit(1);
}

// ---- Resolve/create the Roundcube user ---------------------------------

$user = rcube_user::query($username, $mailHost);
if (!$user) {
    if ($dryRun) {
        log_line("User $username@$mailHost not found, would create it");
        exit(0);
    }
    log_line("User $username@$mailHost not found, creating it");
    $user = rcube_user::create($username, $mailHost);
    if (!$user) {
        fwrite(STDERR, "Failed to create user $username@$mailHost\n");
        exit(1);
    }
}
$rcmail->set_user($user);
log_line("Importing into user_id={$user->ID} ($username @ $mailHost, db " . preg_replace('/:[^:@]*@/', ':***@', $rcmail->config->get('db_dsnw')) . ")");

// ---- Build the new identity values -------------------------------------

$fullname = trim($identity['fullname'] ?? '');
$sigHtml = trim($identity['signature_html'] ?? '');
$sigText = trim($identity['signature'] ?? '');

if ($sigHtml !== '') {
    // Same XSS washing Roundcube applies when a user saves an HTML
    // signature in Settings > Identities (data: URI images survive it).
    $signature = rcmail_action_settings_index::wash_html($sigHtml);
    $isHtml = 1;
} else {
    $signature = $sigText;
    $isHtml = 0;
}

// ---- Update the default identity -----------------------------------------

// get_identity() with no id returns the first identity ordered by
// `standard` DESC, i.e. the default one.
$current = $user->get_identity();

if (!$current) {
    $email = rcube_user::user2email($username) ?: $username;
    $record = [
        'email' => $email,
        'name' => $fullname,
        'standard' => 1,
        'signature' => $signature,
        'html_signature' => $isHtml,
    ];
    if ($dryRun) {
        log_line("No identity found, would create one for <$email>");
        exit(0);
    }
    $plugin = $rcmail->plugins->exec_hook('identity_create', ['record' => $record]);
    if ($plugin['abort']) {
        log_line('identity_create aborted by a plugin');
        exit(1);
    }
    $iid = $user->insert_identity($plugin['record']);
    if (!$iid) {
        fwrite(STDERR, "Failed to create identity\n");
        exit(1);
    }
    $rcmail->plugins->exec_hook('identity_create_after', ['id' => $iid, 'record' => $plugin['record']]);
    log_line("Created identity_id=$iid <$email>");
    log_line('Done.');
    exit(0);
}

$iid = $current['identity_id'];
$changes = [];

if ($fullname !== '' && $fullname !== $current['name']) {
    if (trim($current['name']) === '' || $force) {
        $changes['name'] = $fullname;
    } else {
        log_line("name: keeping existing '{$current['name']}' (use --force to overwrite)");
    }
}

if ($signature !== ''
    && ($signature !== (string) $current['signature'] || $isHtml != $current['html_signature'])
) {
    if (trim((string) $current['signature']) === '' || $force) {
        $changes['signature'] = $signature;
        $changes['html_signature'] = $isHtml;
    } else {
        log_line('signature: keeping existing one (use --force to overwrite)');
    }
}

if (!$changes) {
    log_line("identity_id=$iid <{$current['email']}>: nothing to change");
    log_line('Done.');
    exit(0);
}

$summary = [];
if (isset($changes['name'])) {
    $summary[] = "name '{$changes['name']}'";
}
if (isset($changes['signature'])) {
    $summary[] = ($isHtml ? 'HTML' : 'text') . ' signature (' . strlen($changes['signature']) . ' bytes)';
}
$summary = implode(', ', $summary);

if ($dryRun) {
    log_line("identity_id=$iid <{$current['email']}>: would set $summary");
    exit(0);
}

$plugin = $rcmail->plugins->exec_hook('identity_update', ['id' => $iid, 'record' => $changes]);
if ($plugin['abort']) {
    log_line('identity_update aborted by a plugin');
    exit(1);
}
if (!$user->update_identity($iid, $plugin['record'])) {
    fwrite(STDERR, "Failed to update identity_id=$iid\n");
    exit(1);
}
log_line("identity_id=$iid <{$current['email']}>: set $summary");
log_line('Done.');
