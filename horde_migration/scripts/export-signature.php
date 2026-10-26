<?php
/**
 * Export one Horde mailbox's default identity (full name, plain-text
 * signature and HTML signature) to a JSON file, using Horde's own identity
 * class rather than unserializing horde_prefs by hand.
 *
 * Identities live in the horde-scope 'identities' pref (a serialized array
 * of identities); the 'default_identity' pref is the index of the default
 * one. IMP's signature_html is stored in the same identity array, so the
 * Horde identity is enough - IMP doesn't need to be booted (which would want
 * an IMAP session).
 *
 * Usage: export-signature.php <username> [--out DIR]
 *
 *   <username>   The Horde login / pref_uid, e.g. an email address.
 *   --out DIR    Output directory. Default: /output/<username>/
 *
 * Writes <DIR>/identity.json:
 *   {"fullname": "...", "signature": "...", "signature_html": "..."}
 */

require_once '/srv/www/mail-profissional/source/horde/lib/Application.php';

// ---- CLI args -------------------------------------------------------------

$args = $argv;
array_shift($args);
$user = array_shift($args);
if (!$user) {
    fwrite(STDERR, "Usage: export-signature.php <username> [--out DIR]\n");
    exit(1);
}
$outDir = "/output/$user";
for ($i = 0; $i < count($args); $i++) {
    if ($args[$i] === '--out') {
        $outDir = $args[++$i];
    }
}
if (!is_dir($outDir) && !mkdir($outDir, 0755, true)) {
    fwrite(STDERR, "Cannot create output directory $outDir\n");
    exit(1);
}

function log_line($msg)
{
    fwrite(STDERR, "[export] $msg\n");
}

// ---- Default identity -----------------------------------------------------

Horde_Registry::appInit('horde', array('cli' => true));
$registry->setAuth($user, array());

$identity = $injector->getInstance('Horde_Core_Factory_Identity')->create($user);
$default = $identity->getDefault();

$data = array(
    'fullname' => (string) $identity->getValue('fullname', $default),
    'signature' => (string) $identity->getValue('signature', $default),
    'signature_html' => (string) $identity->getValue('signature_html', $default),
);

$outFile = "$outDir/identity.json";
file_put_contents(
    $outFile,
    json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n"
);

log_line(
    "Identity $default of " . count($identity->getAll('id')) . " for $user ("
    . $data['fullname'] . "): signature " . strlen($data['signature'])
    . " bytes, HTML signature " . strlen($data['signature_html'])
    . " bytes -> $outFile"
);
