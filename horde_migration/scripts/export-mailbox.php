<?php
/**
 * Export one Horde/IMP mailbox's addressbook(s) and calendar(s) to standard
 * vCard 3.0 (.vcf) and iCalendar 2.0 (.ics) files, using Horde/Turba/
 * Kronolith's own exporters (Turba_Driver::tovCard(), Kronolith_Event::
 * toiCalendar()) rather than hand-decoding the DB encoding - see
 * horde_migration/specs/00-overview.md for why.
 *
 * Usage: export-mailbox.php <username> [--limit N] [--out DIR]
 *
 *   <username>   The Horde login / share_owner, e.g. an email address.
 *   --limit N    Export at most N contacts per addressbook and N events per
 *                calendar (for a quick sample run). Default: unlimited.
 *   --out DIR    Output directory. Default: /output/<username>/
 */

require_once '/srv/www/mail-profissional/source/turba/lib/Application.php';

// ---- CLI args -------------------------------------------------------------

$args = $argv;
array_shift($args);
$user = array_shift($args);
if (!$user) {
    fwrite(STDERR, "Usage: export-mailbox.php <username> [--limit N] [--out DIR]\n");
    exit(1);
}
$limit = null;
$outDir = "/output/$user";
for ($i = 0; $i < count($args); $i++) {
    if ($args[$i] === '--limit') {
        $limit = (int) $args[++$i];
    } elseif ($args[$i] === '--out') {
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

// ---- Turba (contacts) ------------------------------------------------------

Horde_Registry::appInit('turba', array('cli' => true));
$registry->setAuth($user, array());

$db = $injector->getInstance('Horde_Db_Adapter');
$turbaShareRows = $db->selectAll(
    'SELECT share_name, attribute_name, attribute_params FROM turba_sharesng WHERE share_owner = ?',
    array($user)
);

$sourcesBase = Turba::availableSources();
$turbaShares = $injector->getInstance('Turba_Factory_Shares')->create($injector);

log_line("Turba: " . count($turbaShareRows) . " addressbook(s) owned by $user");

foreach ($turbaShareRows as $row) {
    $shareName = $row['share_name'];
    $params = @unserialize($row['attribute_params']);
    $source = $params['source'] ?? null;
    if (!$source || empty($sourcesBase[$source])) {
        log_line("  skipping share $shareName: unknown source '$source'");
        continue;
    }

    $share = $turbaShares->getShare($shareName);
    $baseSource = $sourcesBase[$source];

    // Drop map entries pointing at columns this DB snapshot doesn't have
    // (e.g. object_photoorig) - see horde_migration/specs/01-contacts.md.
    $existingColumns = array_flip(array_map(
        function ($c) { return $c->getName(); },
        $db->columns($baseSource['params']['table'])
    ));
    foreach ($baseSource['map'] as $attr => $col) {
        if (is_string($col) && !isset($existingColumns[$col])) {
            unset($baseSource['map'][$attr]);
        }
    }

    $info = $baseSource;
    $info['params']['config'] = $baseSource;
    $info['params']['config']['params']['share'] = $share;
    $info['params']['config']['params']['name'] = $params['name'];
    $info['title'] = $row['attribute_name'];
    $info['type'] = 'share';
    $info['use_shares'] = false;

    $driver = $injector->getInstance('Turba_Factory_Driver')
        ->create($shareName, '', array($shareName => $info));

    $list = $driver->search(array());
    $objects = $list->objects;
    $total = count($objects);
    if ($limit !== null) {
        $objects = array_slice($objects, 0, $limit);
    }

    $outFile = "$outDir/contacts-$shareName.vcf";
    $fh = fopen($outFile, 'w');
    $written = 0;
    foreach ($objects as $object) {
        if ($object->getValue('__type') === 'Group') {
            // Distribution lists need member-UID resolution, handled
            // separately per horde_migration/specs/01-contacts.md #1.3 -
            // not part of a plain vCard export.
            continue;
        }
        $vcard = $driver->tovCard($object, '3.0', null, true);
        fwrite($fh, $vcard->exportvCalendar());
        $written++;
    }
    fclose($fh);
    log_line("  $shareName ({$info['title']}): $written/$total contact(s) -> $outFile");
}

// ---- Kronolith (calendar) --------------------------------------------------

require_once '/srv/www/mail-profissional/source/kronolith/lib/Application.php';
Horde_Registry::appInit('kronolith', array('cli' => true));
$registry->setAuth($user, array());

// Kronolith_Driver_Sql::backgroundColor() unconditionally reads this global
// on every event construction; stub it rather than pulling in the real
// Kronolith::initialize() (permission checks, external/holiday calendars -
// irrelevant to a plain data export).
$GLOBALS['calendar_manager'] = new class {
    public function getEntry($type, $id) { return false; }
};

$kdb = $injector->getInstance('Horde_Db_Adapter');
// Note: this DB snapshot predates the resources-to-shares migration (no
// attribute_calendar_type column), so there's no way to distinguish a
// resource calendar from a personal one at this level - see
// horde_migration/specs/02-calendar.md #1.1. Every share owned by $user is
// treated as a personal calendar.
$kronolithShareRows = $kdb->selectAll(
    "SELECT share_name, attribute_name FROM kronolith_sharesng WHERE share_owner = ?",
    array($user)
);

log_line("Kronolith: " . count($kronolithShareRows) . " calendar(s) owned by $user");

foreach ($kronolithShareRows as $row) {
    $shareName = $row['share_name'];
    $driver = Kronolith::getDriver('Sql', $shareName);
    $eventsByDay = $driver->listEvents(null, null, array('cover_dates' => false));

    $flat = array();
    foreach ($eventsByDay as $dayEvents) {
        foreach ($dayEvents as $event) {
            $flat[$event->uid] = $event;
        }
    }
    $total = count($flat);
    $events = $limit !== null ? array_slice($flat, 0, $limit, true) : $flat;

    $iCal = new Horde_Icalendar('2.0');
    $iCal->setAttribute('X-WR-CALNAME', $row['attribute_name']);
    foreach ($events as $event) {
        $iCal->addComponent($event->toiCalendar($iCal));
    }

    $outFile = "$outDir/calendar-$shareName.ics";
    file_put_contents($outFile, $iCal->exportvCalendar());
    log_line("  $shareName ({$row['attribute_name']}): " . count($events) . "/$total event(s) -> $outFile");
}

log_line("Done.");
