<?php
/**
 * Import one mailbox's exported Horde data (produced by export-mailbox.php:
 * contacts-*.vcf + calendar-*.ics files in a directory) into Roundcube,
 * using Roundcube's own APIs (rcube_contacts::insert(), the xcalendar
 * plugin's Event::importEvents()) rather than hand-writing SQL - see
 * horde_migration/specs/01-contacts.md and 02-calendar.md.
 *
 * Usage: import-mailbox.php <export-dir> [--user USERNAME] [--mail-host HOST]
 *
 *   <export-dir>   Directory produced by export-mailbox.php, e.g.
 *                  horde_migration/export-output/sergio.carvalho@portugalmail.pt
 *   --user         Roundcube username (default: basename of <export-dir>)
 *   --mail-host    Roundcube users.mail_host to resolve/create the account
 *                  under (default: 10.5.2.41, matching the existing test
 *                  users - see horde_migration/specs/00-overview.md #8.1)
 */

define('INSTALL_PATH', '/home/sergio/Projects/Sooma/Profissional/webmail-roundcube/');
chdir(INSTALL_PATH);

// config/config.inc.php ends in a per-vhost override block keyed off
// HTTP_HOST that (a) points db_dsnw at this exact test DB for the vhosts
// already set up here, and (b) trims the plugin list to a safe subset.
// With HTTP_HOST unset (plain CLI) that block resolves its own path back
// to itself and recurses forever - see horde_migration/scripts/
// rc-smoke-test.php for how this was diagnosed.
$_SERVER['HTTP_HOST'] = 'correio.portugalmail.pt';

require_once INSTALL_PATH . 'program/include/clisetup.php';

function log_line($msg)
{
    fwrite(STDERR, "[import] $msg\n");
}

// ---- CLI args ---------------------------------------------------------

$args = $argv;
array_shift($args);
$exportDir = array_shift($args);
if (!$exportDir || !is_dir($exportDir)) {
    fwrite(STDERR, "Usage: import-mailbox.php <export-dir> [--user USERNAME] [--mail-host HOST]\n");
    exit(1);
}
$exportDir = rtrim($exportDir, '/');
$username = basename($exportDir);
$mailHost = '10.5.2.41';
for ($i = 0; $i < count($args); $i++) {
    if ($args[$i] === '--user') {
        $username = $args[++$i];
    } elseif ($args[$i] === '--mail-host') {
        $mailHost = $args[++$i];
    }
}

// ---- Resolve/create the Roundcube user ---------------------------------

$user = rcube_user::query($username, $mailHost);
if (!$user) {
    log_line("User $username@$mailHost not found, creating it");
    $user = rcube_user::create($username, $mailHost);
    if (!$user) {
        fwrite(STDERR, "Failed to create user $username@$mailHost\n");
        exit(1);
    }
}
$rcmail->set_user($user);
log_line("Importing into user_id={$user->ID} ($username @ $mailHost)");

$db = $rcmail->get_dbh();

function already_imported($db, $sourceType, $sourceUid, $userId)
{
    $res = $db->query(
        'SELECT target_id FROM horde_migration_map WHERE source_type = ? AND source_uid = ? AND user_id = ?',
        $sourceType, $sourceUid, $userId
    );
    $row = $db->fetch_assoc($res);
    return $row ? $row['target_id'] : null;
}

function record_imported($db, $sourceType, $sourceUid, $userId, $targetId)
{
    $db->query(
        'INSERT INTO horde_migration_map (source_type, source_uid, user_id, target_id) VALUES (?, ?, ?, ?)',
        $sourceType, $sourceUid, $userId, $targetId
    );
}

/**
 * Kronolith exports a modified occurrence of a recurring event as its own
 * VEVENT sharing the master's UID plus a RECURRENCE-ID. The xcalendar
 * plugin has no column for RECURRENCE-ID, and Event::importEvents()
 * upserts by (vevent_uid, calendar_id, user_id) - so every VEVENT sharing
 * a UID collapses onto the SAME xcalendar_events row, each one clobbering
 * the last. Confirmed empirically: a master with 10 modified occurrences
 * (11 VEVENTs, same UID) collapsed into 1 row with its RRULE wiped out.
 *
 * Fix (per horde_migration/specs/02-calendar.md #2.3): pull every
 * RECURRENCE-ID VEVENT out, give it a fresh deterministic UID (so re-runs
 * stay idempotent) and drop the RECURRENCE-ID, turning it into its own
 * standalone non-recurring event; and make sure the master's own VEVENT
 * excludes that occurrence's original date (EXDATE) so the recurring
 * series doesn't also generate a phantom duplicate on top of it.
 *
 * @return string  A rebuilt ICS text, safe to hand to importEvents().
 */
function flatten_recurrence_overrides($ics)
{
    if (!preg_match('/^(.*?)(?=BEGIN:VEVENT)/s', $ics, $m)) {
        return $ics; // no VEVENTs at all - nothing to do
    }
    $header = $m[1];
    preg_match_all('/BEGIN:VEVENT.*?END:VEVENT\R?/s', $ics, $m2);
    $footer = "END:VCALENDAR\r\n";

    $masters = [];        // uid => block text, in original order
    $overrideBlocks = [];  // flattened, ready-to-import override blocks
    $exdatesByUid = [];    // uid => [unique EXDATE line => true]

    foreach ($m2[0] as $block) {
        if (!preg_match('/^UID:(.+)$/mi', $block, $um)) {
            continue; // malformed block, shouldn't happen with our own export
        }
        $uid = trim($um[1]);

        if (preg_match('/^RECURRENCE-ID(?:;[^:]*)?:.+$/mi', $block, $rm)) {
            $recurrenceIdLine = trim($rm[0]);
            $recurrenceIdValue = substr($recurrenceIdLine, strpos($recurrenceIdLine, ':') + 1);

            $newUid = $uid . '.flattened-' . preg_replace('/[^0-9A-Za-z]/', '', $recurrenceIdValue);
            $flat = preg_replace('/^UID:.*$/mi', 'UID:' . $newUid, $block, 1);
            $flat = preg_replace('/^RECURRENCE-ID(?:;[^:]*)?:.+$\R?/mi', '', $flat, 1);
            $flat = preg_replace('/^RRULE:.*$\R?/mi', '', $flat); // defensive; overrides shouldn't have one
            $overrideBlocks[$newUid] = $flat; // keyed by new uid: de-dupes repeated source rows for the same occurrence

            $exdateLine = preg_replace('/^RECURRENCE-ID/i', 'EXDATE', $recurrenceIdLine);
            $exdatesByUid[$uid][$exdateLine] = true;
        } else {
            $masters[$uid] = $block; // master or plain standalone event
        }
    }

    foreach ($exdatesByUid as $uid => $lines) {
        if (!isset($masters[$uid])) {
            continue; // override's master isn't in this export - nothing to inject into
        }
        foreach (array_keys($lines) as $exdateLine) {
            $value = substr($exdateLine, strpos($exdateLine, ':'));
            if (strpos($masters[$uid], $value) !== false) {
                continue; // this date is already excluded (or was never included)
            }
            $masters[$uid] = preg_replace('/(END:VEVENT)/', $exdateLine . "\r\n$1", $masters[$uid], 1);
        }
    }

    return $header . implode('', array_values($masters)) . implode('', array_values($overrideBlocks)) . $footer;
}

// ---- Contacts -----------------------------------------------------------

$CONTACTS = new rcube_contacts($db, $user->ID);

$vcfFiles = glob("$exportDir/contacts-*.vcf");
log_line(count($vcfFiles) . " contact export file(s) found");

foreach ($vcfFiles as $vcfFile) {
    $text = file_get_contents($vcfFile);
    // rcube_vcard::import() splits a multi-vcard blob into rcube_vcard
    // objects but doesn't track the UID property at all (Roundcube has no
    // use for an externally-assigned UID) - so we split blocks ourselves
    // to pull the UID out by regex alongside letting rcube_vcard parse
    // the fields, for our own idempotency bookkeeping.
    preg_match_all('/BEGIN:VCARD.*?END:VCARD\R?/is', $text, $matches);
    $blocks = $matches[0];

    $imported = 0;
    $skipped = 0;
    $failed = 0;

    foreach ($blocks as $block) {
        $uid = null;
        if (preg_match('/^UID:(.+)$/mi', $block, $m)) {
            $uid = trim($m[1]);
        }

        if ($uid && already_imported($db, 'contact', $uid, $user->ID)) {
            $skipped++;
            continue;
        }

        $vcard = new rcube_vcard($block);
        $assoc = $vcard->get_assoc();
        if (empty($assoc)) {
            $failed++;
            continue;
        }

        $contactId = $CONTACTS->insert($assoc);
        if (!$contactId) {
            $failed++;
            continue;
        }
        if ($uid) {
            record_imported($db, 'contact', $uid, $user->ID, $contactId);
        }
        $imported++;
    }

    log_line(basename($vcfFile) . ": $imported imported, $skipped already imported, $failed failed (of " . count($blocks) . ")");
}

// ---- Calendar -------------------------------------------------------------

\XCalendar\CalendarData::createDefaultCalendar();

$icsFiles = glob("$exportDir/calendar-*.ics");
log_line(count($icsFiles) . " calendar export file(s) found");

$defaultCalendarId = null;
if ($icsFiles) {
    $defaultCalendarId = \XCalendar\CalendarData::loadDefault()->get('id');
}

foreach ($icsFiles as $i => $icsFile) {
    $ics = flatten_recurrence_overrides(file_get_contents($icsFile));

    // Reuse the auto-created default calendar for the first (or only)
    // exported calendar; create a fresh one for any additional calendars
    // this mailbox owned in Horde - see horde_migration/specs/02-calendar.md #4.
    if ($i === 0) {
        $calendarId = $defaultCalendarId;
    } else {
        $calendarData = \XCalendar\CalendarData::loadEmpty();
        $calendarId = $calendarData->save();
    }

    $event = new \XCalendar\Event();
    $result = $event->importEvents($ics, $calendarId);
    if ($result === false) {
        log_line(basename($icsFile) . ": import failed (see Roundcube error log)");
        continue;
    }
    log_line(basename($icsFile) . ": {$result['success']} imported, {$result['error']} failed, into calendar_id=$calendarId");
}

log_line('Done.');
