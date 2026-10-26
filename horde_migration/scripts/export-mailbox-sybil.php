<?php
/**
 * Export one mail-gratuito mailbox's Sybil addressbook(s) to standard vCard
 * 3.0 (.vcf) files, in the same layout export-mailbox.php produces for
 * Turba, so import-mailbox.php can consume them unchanged.
 *
 * Sybil is Portugalmail's in-house replacement for Turba on the older
 * (gratuito) Horde install. Unlike Turba, its own exporter
 * (Sybil_Contact::tovCard(), sybil/lib/Contact.php) is too incomplete to
 * reuse - FN is just the first name, every card gets an empty TEL;PREF, and
 * IMs, photos and a UID are never written - and booting that Horde 4 tree
 * just for it isn't worth it. Sybil's schema is flat (one table per
 * multi-valued property, no serialized blobs), so this script reads it
 * directly over PDO and writes the vCards itself.
 *
 * Data model (verified against the live DB):
 *   - A user's contacts are sybil_contact rows with contact_idowner = <user>
 *     and contact_type = 'contact'. contact_addressbook is NULL for the
 *     default book, or a sybil_addressbook.addressbook_id. contact_idowner is
 *     the book's owner even for share-owned books (addressbook_owner =
 *     sybil_sharesng.share_name), so no share resolution is needed.
 *   - The user's own card is the contact_type = 'profile' row; it's not a
 *     contact and isn't exported. The sybil_card* tables (about me,
 *     education, work history, languages, websocials) only ever hang off
 *     profiles, so they're not read either.
 *   - Emails/phones/IMs/websites/addresses live in sybil_contact{email,
 *     phone,im,website,address}, each typed 'personal' or 'professional'.
 *     Addresses are one free-text blob (often multi-line), not split fields.
 *   - When a contact has an accepted connection to another user's profile
 *     (sybil_connection.connection_contact_id), Sybil's UI shows the
 *     profile's typed properties merged into the contact's
 *     (Sybil_Contact::getAllFromType()); we do the same.
 *   - Social groups (sybil_socialgroup) belong to the user's profile, with
 *     members in sybil_rel_contact_socialgroup. They're written to the JSON
 *     sidecar (sybil-metadata.json) as member UIDs, per
 *     horde_migration/specs/00-overview.md #3 - vCard has no portable way to
 *     carry them and rcube_contacts drops CATEGORIES on insert anyway.
 *   - Photos are files on the old webmail servers, not in the DB
 *     (Sybil_Photo::userPath()); they're only embedded if --photos-dir points
 *     at a copy of that uploads tree.
 *
 * Sybil has no stable contact UID, so one is derived from the PK:
 * "sybil-<contact_id>". It's what import-mailbox.php keys its idempotency
 * bookkeeping on, and what the sidecar's group member lists refer to.
 *
 * Usage: export-mailbox-sybil.php <username> [--limit N] [--out DIR]
 *            [--photos-dir DIR] [--dsn DSN] [--db-user U] [--db-pass P]
 *
 *   <username>    The Horde login / contact_idowner, e.g. an email address.
 *   --limit N     Export at most N contacts per addressbook. Default:
 *                 unlimited.
 *   --out DIR     Output directory. Default: /output/<username>/ when run
 *                 via docker/run.sh, else ../export-output/<username>/.
 *   --photos-dir  Root of Sybil's images uploads_path. Default: none
 *                 (photos are skipped).
 *   --dsn, --db-user, --db-pass
 *                 Database connection. Default: the mail_gratuito DB at
 *                 10.3.1.126, user postgres, no password.
 */

// ---- CLI args -------------------------------------------------------------

$args = $argv;
array_shift($args);
$user = array_shift($args);
if (!$user) {
    fwrite(STDERR, "Usage: export-mailbox-sybil.php <username> [--limit N] [--out DIR] [--photos-dir DIR] [--dsn DSN] [--db-user U] [--db-pass P]\n");
    exit(1);
}
$limit = null;
$outDir = (is_dir('/output') ? '/output' : dirname(__DIR__) . '/export-output') . "/$user";
$photosDir = null;
$dsn = 'pgsql:host=10.3.1.126;port=5432;dbname=mail_gratuito';
$dbUser = 'postgres';
$dbPass = '';
for ($i = 0; $i < count($args); $i++) {
    if ($args[$i] === '--limit') {
        $limit = (int) $args[++$i];
    } elseif ($args[$i] === '--out') {
        $outDir = $args[++$i];
    } elseif ($args[$i] === '--photos-dir') {
        $photosDir = rtrim($args[++$i], '/');
    } elseif ($args[$i] === '--dsn') {
        $dsn = $args[++$i];
    } elseif ($args[$i] === '--db-user') {
        $dbUser = $args[++$i];
    } elseif ($args[$i] === '--db-pass') {
        $dbPass = $args[++$i];
    }
}
if (!is_dir($outDir) && !mkdir($outDir, 0755, true)) {
    fwrite(STDERR, "Cannot create output directory $outDir\n");
    exit(1);
}

function log_line($msg)
{
    fwrite(STDERR, "[export-sybil] $msg\n");
}

// ---- vCard 3.0 serialization ----------------------------------------------

/** Escape a TEXT value (RFC 2426 #4). */
function vc_escape($value)
{
    $value = str_replace(array("\r\n", "\r"), "\n", (string) $value);
    return strtr($value, array('\\' => '\\\\', ',' => '\,', ';' => '\;', "\n" => '\n'));
}

/** Fold a content line at 75 octets without splitting a UTF-8 sequence. */
function vc_fold($line)
{
    $out = '';
    $max = 75;
    while (strlen($line) > $max) {
        $cut = $max;
        // Back off continuation bytes (10xxxxxx) so we cut before a lead byte.
        while ($cut > 0 && (ord($line[$cut]) & 0xC0) === 0x80) {
            $cut--;
        }
        $out .= substr($line, 0, $cut) . "\r\n ";
        $line = substr($line, $cut);
        $max = 74; // continuation lines start with the folding space
    }
    return $out . $line . "\r\n";
}

/**
 * One content line. $value is either a string (escaped as TEXT) or an array
 * of components (each escaped, joined with ';' - for N and ADR).
 */
function vc_line($name, $value, array $types = array(), $raw = false)
{
    if (is_array($value)) {
        $value = implode(';', array_map('vc_escape', $value));
    } elseif (!$raw) {
        $value = vc_escape($value);
    }
    $params = $types ? ';TYPE=' . implode(',', $types) : '';
    return vc_fold($name . $params . ':' . $value);
}

function has_value($v)
{
    return $v !== null && trim($v) !== '';
}

// TYPE values below are picked to land on Roundcube's own subtypes:
// rcube_vcard::get_assoc() uses the first TYPE (ignoring INTERNET/PREF),
// except for the combined forms in its $typemap ('CELL' -> mobile,
// 'WORK,FAX' -> workfax). 'HOMEFAX' is non-standard but is literally what
// Roundcube itself writes for its homefax subtype.
function phone_types($kind, $model)
{
    $work = $kind === 'professional';
    switch ($model) {
    case 'Mobile':
        return array('CELL');
    case 'Fax':
        return $work ? array('WORK', 'FAX') : array('HOMEFAX');
    case 'Pager':
        return array('PAGER');
    default: // 'Land'
        return $work ? array('WORK', 'VOICE') : array('HOME', 'VOICE');
    }
}

function kind_type($kind)
{
    return $kind === 'professional' ? 'WORK' : 'HOME';
}

// Sybil stores free-form client names with inconsistent case ('MSN',
// 'Yahoo', 'YAHOO', 'false', ...) - map to the X- properties rcube_vcard
// reads ($immap). Unknown clients have no Roundcube field; returns null.
function im_property($client)
{
    $map = array(
        'msn' => 'X-MSN',
        'skype' => 'X-SKYPE',
        'gtalk' => 'X-JABBER', // Google Talk was XMPP
        'jabber' => 'X-JABBER',
        'aim' => 'X-AIM',
        'yahoo' => 'X-YAHOO',
        'icq' => 'X-ICQ',
    );
    $client = strtolower(trim($client));
    return isset($map[$client]) ? $map[$client] : null;
}

/**
 * Build the vCard text for one contact.
 *
 * @param array $c     The sybil_contact row.
 * @param array $props Typed properties: 'emails', 'phones', 'ims',
 *                     'websites', 'addresses', each a list of
 *                     [kind, value, extra] (extra = phone model / IM client).
 * @param string|null $photo Raw JPEG bytes, if available.
 * @param array $unmapped    Appended to: lines of data with no vCard target.
 */
function build_vcard(array $c, array $props, $photo, array &$unmapped)
{
    $v = "BEGIN:VCARD\r\nVERSION:3.0\r\n";
    $v .= vc_line('UID', 'sybil-' . $c['contact_id']);

    $n = array(
        (string) $c['contact_lastname'],
        (string) $c['contact_firstname'],
        (string) $c['contact_middlenames'],
        (string) $c['contact_nameprefix'],
        (string) $c['contact_namesuffix'],
    );
    $fn = trim(preg_replace('/\s+/u', ' ', implode(' ', array(
        $n[3], $n[1], $n[2], $n[0], $n[4],
    ))));
    // FN is mandatory. Most Sybil contacts only have a first name (which
    // often holds the full name) and a main email - fall back sensibly.
    if ($fn === '') {
        foreach (array('contact_nickname', 'contact_company', 'contact_mainemail') as $col) {
            if (has_value($c[$col])) {
                $fn = trim($c[$col]);
                break;
            }
        }
    }
    $v .= vc_line('FN', $fn);
    $v .= vc_line('N', $n);

    if (has_value($c['contact_nickname'])) {
        $v .= vc_line('NICKNAME', $c['contact_nickname']);
    }
    if (has_value($c['contact_company'])) {
        $v .= vc_line('ORG', array($c['contact_company']));
    }
    if (has_value($c['contact_jobposition'])) {
        $v .= vc_line('TITLE', $c['contact_jobposition']);
    }
    if (has_value($c['contact_birthday'])) {
        $v .= vc_line('BDAY', substr($c['contact_birthday'], 0, 10), array(), true);
    }
    $gender = strtolower(trim((string) $c['contact_gender']));
    if ($gender === 'male' || $gender === 'female') {
        $v .= vc_line('X-GENDER', $gender);
    }

    // Emails: main first (PREF), then alternative, then typed - de-duped,
    // since the main email is frequently repeated in the typed list.
    $seen = array();
    $emails = array();
    if (has_value($c['contact_mainemail'])) {
        $emails[] = array(array('INTERNET', 'HOME', 'PREF'), $c['contact_mainemail']);
    }
    if (has_value($c['contact_alternativeemail'])) {
        $emails[] = array(array('INTERNET', 'OTHER'), $c['contact_alternativeemail']);
    }
    foreach ($props['emails'] as $e) {
        $emails[] = array(array('INTERNET', kind_type($e[0])), $e[1]);
    }
    foreach ($emails as $e) {
        $addr = trim($e[1]);
        $key = strtolower($addr);
        if ($addr === '' || isset($seen[$key])) {
            continue;
        }
        $seen[$key] = true;
        $v .= vc_line('EMAIL', $addr, $e[0]);
    }

    $seen = array();
    if (has_value($c['contact_mainphone'])) {
        $seen[trim($c['contact_mainphone'])] = true;
        $v .= vc_line('TEL', trim($c['contact_mainphone']), array('MAIN', 'PREF'));
    }
    foreach ($props['phones'] as $p) {
        $num = trim($p[1]);
        if ($num === '' || isset($seen[$num])) {
            continue;
        }
        $seen[$num] = true;
        $v .= vc_line('TEL', $num, phone_types($p[0], $p[2]));
    }

    foreach ($props['addresses'] as $a) {
        if (!has_value($a[1])) {
            continue;
        }
        // Free text only - goes in the street component, as Sybil's own
        // tovCard() does; there's nothing reliable to split it on.
        $v .= vc_line('ADR', array('', '', trim($a[1]), '', '', '', ''), array(kind_type($a[0])));
    }

    foreach ($props['websites'] as $w) {
        if (has_value($w[1])) {
            $v .= vc_line('URL', trim($w[1]), array($w[0] === 'professional' ? 'WORK' : 'HOMEPAGE'), true);
        }
    }

    // Handles with an unknown client go to NOTE - unless the same handle is
    // also stored under a known one (common: Sybil often saved a duplicate
    // row with client 'false').
    $mapped = array();
    $other = array();
    foreach ($props['ims'] as $im) {
        $handle = trim((string) $im[1]);
        if ($handle === '') {
            continue;
        }
        $prop = im_property($im[2]);
        if ($prop) {
            if (!isset($mapped[$prop . ':' . $handle])) {
                $v .= vc_line($prop, $handle);
            }
            $mapped[$prop . ':' . $handle] = $mapped[$handle] = true;
        } else {
            $other[$handle] = 'IM' . (has_value($im[2]) && $im[2] !== 'false' ? " ({$im[2]})" : '') . ": $handle";
        }
    }
    foreach ($other as $handle => $line) {
        if (!isset($mapped[$handle])) {
            $unmapped[] = $line;
        }
    }

    $notes = (string) $c['contact_notes'];
    if ($unmapped) {
        $notes = rtrim($notes) . ($notes !== '' ? "\n\n" : '') . implode("\n", $unmapped);
    }
    if (trim($notes) !== '') {
        $v .= vc_line('NOTE', $notes);
    }

    if ($photo !== null) {
        $v .= vc_line('PHOTO;ENCODING=b;TYPE=JPEG', base64_encode($photo), array(), true);
    }

    return $v . "END:VCARD\r\n";
}

// ---- Load -------------------------------------------------------------------

$db = new PDO($dsn, $dbUser, $dbPass, array(
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
));
$db->exec("SET client_encoding = 'UTF8'");

function select_all(PDO $db, $sql, array $params)
{
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}

$profile = select_all($db,
    "SELECT contact_id FROM sybil_contact WHERE contact_idowner = ? AND contact_type = 'profile'",
    array($user)
);
$profileId = $profile ? (int) $profile[0]['contact_id'] : null;

$contacts = select_all($db,
    "SELECT * FROM sybil_contact WHERE contact_idowner = ? AND contact_type = 'contact' ORDER BY contact_id",
    array($user)
);
if (!$contacts && $profileId === null) {
    log_line("No Sybil profile or contacts for $user");
}

// Typed properties for all of the user's contacts in one query per table,
// keyed by contact id. Also used below for connected profiles.
$PROPERTY_QUERIES = array(
    'emails' => 'SELECT contactemail_contact_id AS cid, contactemail_type AS kind, contactemail_email AS value, NULL AS extra
                 FROM sybil_contactemail WHERE contactemail_contact_id = ANY (?::int[]) ORDER BY contactemail_id',
    'phones' => 'SELECT contactphone_contact_id AS cid, contactphone_type AS kind, contactphone_phone AS value, contactphone_model AS extra
                 FROM sybil_contactphone WHERE contactphone_contact_id = ANY (?::int[]) ORDER BY contactphone_id',
    'ims' => 'SELECT contactim_contact_id AS cid, contactim_type AS kind, contactim_im AS value, contactim_client AS extra
              FROM sybil_contactim WHERE contactim_contact_id = ANY (?::int[]) ORDER BY contactim_id',
    'websites' => 'SELECT contactwebsite_contact_id AS cid, contactwebsite_type AS kind, contactwebsite_website AS value, NULL AS extra
                   FROM sybil_contactwebsite WHERE contactwebsite_contact_id = ANY (?::int[]) ORDER BY contactwebsite_id',
    'addresses' => 'SELECT contactaddress_contact_id AS cid, contactaddress_type AS kind, contactaddress_address AS value, NULL AS extra
                    FROM sybil_contactaddress WHERE contactaddress_contact_id = ANY (?::int[]) ORDER BY contactaddress_id',
);

function load_properties(PDO $db, array $queries, array $ids)
{
    $props = array();
    foreach ($ids as $id) {
        $props[$id] = array_fill_keys(array_keys($queries), array());
    }
    if (!$ids) {
        return $props;
    }
    $idArray = '{' . implode(',', array_map('intval', $ids)) . '}';
    foreach ($queries as $name => $sql) {
        foreach (select_all($db, $sql, array($idArray)) as $row) {
            $props[$row['cid']][$name][] = array($row['kind'], $row['value'], $row['extra']);
        }
    }
    return $props;
}

$contactIds = array_map(function ($c) { return (int) $c['contact_id']; }, $contacts);
$props = load_properties($db, $PROPERTY_QUERIES, $contactIds);

// Accepted connections: contact id => connected profile id.
$connections = array();
if ($profileId !== null) {
    foreach (select_all($db,
        "SELECT connection_contact_id, connection_receiver_id FROM sybil_connection
         WHERE connection_requester_id = ? AND connection_status = 'accepted'
           AND connection_contact_id IS NOT NULL AND connection_receiver_id IS NOT NULL",
        array($profileId)
    ) as $row) {
        $connections[(int) $row['connection_contact_id']] = (int) $row['connection_receiver_id'];
    }
}
if ($connections) {
    $profileProps = load_properties($db, $PROPERTY_QUERIES, array_values(array_unique($connections)));
    foreach ($connections as $cid => $pid) {
        if (!isset($props[$cid])) {
            continue;
        }
        // Mirror Sybil_Contact::getAllFromType(): append the profile's
        // values the contact doesn't already have (same kind + value).
        foreach ($profileProps[$pid] as $name => $list) {
            foreach ($list as $p) {
                if (!in_array($p, $props[$cid][$name])) {
                    $props[$cid][$name][] = $p;
                }
            }
        }
    }
}

function load_photo($photosDir, $owner, $name)
{
    if ($photosDir === null || !has_value($name)) {
        return null;
    }
    // Sybil_Photo::userPath(), non-square variant.
    $md5 = md5($owner);
    $path = sprintf('%s/%s/%s/%s/%s', $photosDir, substr($md5, 0, 2), substr($md5, 2, 2), $owner, $name);
    if (!is_file($path)) {
        return null;
    }
    $data = file_get_contents($path);
    return $data === false ? null : $data;
}

// ---- Export, one .vcf per addressbook ---------------------------------------

$bookRows = select_all($db,
    'SELECT addressbook_id, addressbook_name, addressbook_owner FROM sybil_addressbook
     WHERE addressbook_id IN (SELECT DISTINCT contact_addressbook FROM sybil_contact
                              WHERE contact_idowner = ? AND contact_type = \'contact\')
        OR addressbook_owner = ?
        OR addressbook_owner IN (SELECT share_name FROM sybil_sharesng WHERE share_owner = ?)',
    array($user, $user, $user)
);
$books = array('' => array('name' => null)); // the default book (NULL contact_addressbook)
foreach ($bookRows as $b) {
    $books[$b['addressbook_id']] = array('name' => $b['addressbook_name']);
}

$byBook = array();
foreach ($contacts as $c) {
    $byBook[(string) $c['contact_addressbook']][] = $c;
}

log_line(count($contacts) . " contact(s) in " . count($books) . " addressbook(s) owned by $user"
    . ($connections ? ', ' . count($connections) . ' with an accepted connection' : ''));

$metadata = array('source' => 'sybil', 'user' => $user, 'addressbooks' => array(), 'groups' => array());
$exportedUids = array();
$photos = 0;

foreach ($books as $bookId => $book) {
    $bookId = (string) $bookId; // PHP turns numeric-looking keys into ints
    $isDefault = $bookId === '';
    $rows = isset($byBook[$bookId]) ? $byBook[$bookId] : array();
    $total = count($rows);
    if ($limit !== null) {
        $rows = array_slice($rows, 0, $limit);
    }

    $fileKey = $isDefault ? 'default' : $bookId;
    $outFile = "$outDir/contacts-sybil-$fileKey.vcf";
    $fh = fopen($outFile, 'w');
    foreach ($rows as $c) {
        $cid = (int) $c['contact_id'];
        $photo = load_photo($photosDir, $user, $c['contact_cardphoto_name']);
        if ($photo !== null) {
            $photos++;
        }
        $unmapped = array();
        fwrite($fh, build_vcard($c, $props[$cid], $photo, $unmapped));
        $exportedUids['sybil-' . $cid] = true;
    }
    fclose($fh);

    $title = $isDefault ? '(default)' : $book['name'];
    $metadata['addressbooks'][] = array(
        'id' => $isDefault ? null : $bookId,
        'name' => $book['name'],
        'default' => $isDefault,
        'file' => basename($outFile),
    );
    log_line("  $fileKey ($title): " . count($rows) . "/$total contact(s) -> $outFile");
}
if ($photosDir !== null) {
    log_line("  $photos photo(s) embedded");
}

// ---- Social groups -> sidecar ------------------------------------------------

if ($profileId !== null) {
    $groups = select_all($db,
        'SELECT socialgroup_id, socialgroup_name, socialgroup_description, socialgroup_notes, socialgroup_addressbook
         FROM sybil_socialgroup WHERE socialgroup_contact_id = ? ORDER BY socialgroup_id',
        array($profileId)
    );
    $members = array();
    if ($groups) {
        $groupIds = '{' . implode(',', array_map(function ($g) { return (int) $g['socialgroup_id']; }, $groups)) . '}';
        foreach (select_all($db,
            'SELECT rel_contact_socialgroup_socialgroup_id AS gid, rel_contact_socialgroup_contact_id AS cid
             FROM sybil_rel_contact_socialgroup WHERE rel_contact_socialgroup_socialgroup_id = ANY (?::int[])
             ORDER BY 1, 2',
            array($groupIds)
        ) as $row) {
            $uid = 'sybil-' . $row['cid'];
            // Only reference contacts actually written out (--limit, or a
            // stray membership pointing at someone else's contact).
            if (isset($exportedUids[$uid])) {
                $members[$row['gid']][] = $uid;
            }
        }
    }
    foreach ($groups as $g) {
        $metadata['groups'][] = array(
            'name' => $g['socialgroup_name'],
            'description' => $g['socialgroup_description'],
            'notes' => $g['socialgroup_notes'],
            'addressbook' => $g['socialgroup_addressbook'],
            'members' => isset($members[$g['socialgroup_id']]) ? $members[$g['socialgroup_id']] : array(),
        );
    }
    log_line(count($groups) . " social group(s), "
        . array_sum(array_map('count', $members)) . " membership(s)");
}

$metaFile = "$outDir/sybil-metadata.json";
file_put_contents($metaFile, json_encode($metadata, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n");
log_line("Metadata -> $metaFile");

log_line("Done.");
