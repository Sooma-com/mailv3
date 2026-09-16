<?php
/**
 * Smoke test: boot Turba and Kronolith via the real Horde application
 * framework (against the read-only export DB), resolve one specific
 * addressbook/calendar share directly by its known share_name (exactly
 * like Turba_Factory_Driver::create()'s own "admin needs access to
 * another user's sources" override parameter is meant for - we already
 * know the share_name from our own read-only SQL inventory pass, so we
 * don't need to simulate a real user's session/permission-filtered share
 * listing at all). Proves the local bootstrap works end to end before
 * writing the real export logic.
 */

$user = 'construcoes.marianinho@oninet.pt';
$turbaShareName = 'PfbKVZuwDI6QlN4dUDXE0DY';
$kronolithShareName = 'a-2DMSdgLOlCbcn6QJNU30_';

require_once '/srv/www/mail-profissional/source/turba/lib/Application.php';
Horde_Registry::appInit('turba', array('cli' => true));
$registry->setAuth($user, array());

echo "=== Turba ===\n";

$sourcesBase = Turba::availableSources();
$shares = $injector->getInstance('Turba_Factory_Shares')->create($injector);
$share = $shares->getShare($turbaShareName);
echo "Share found: " . $share->get('name') . " (owner=" . $share->get('owner') . ")\n";

$params = @unserialize($share->get('params'));
$baseSource = $sourcesBase[$params['source']];

// This read-only replica's turba_objects schema is missing a few columns
// that backends.php's map still references (e.g. object_photoorig) - drop
// any map entry pointing at a column that doesn't actually exist here,
// without touching the real (shared) backends.php config file.
$db = $injector->getInstance('Horde_Db_Adapter');
$existingColumns = array_flip(array_map(
    function ($c) { return $c->getName(); },
    $db->columns($baseSource['params']['table'])
));
foreach ($baseSource['map'] as $attr => $col) {
    if (is_string($col) && !isset($existingColumns[$col])) {
        echo "  (dropping map entry '$attr' => '$col': column missing in this DB)\n";
        unset($baseSource['map'][$attr]);
    }
}

$info = $baseSource;
$info['params']['config'] = $baseSource;
$info['params']['config']['params']['share'] = $share;
$info['params']['config']['params']['name'] = $params['name'];
$info['title'] = $share->get('name');
$info['type'] = 'share';
$info['use_shares'] = false;

$driver = $injector->getInstance('Turba_Factory_Driver')
    ->create($turbaShareName, '', array($turbaShareName => $info));
$list = $driver->search(array());
echo "Contacts: " . count($list->objects) . "\n";
foreach (array_slice($list->objects, 0, 3) as $obj) {
    echo "   uid=" . $obj->getValue('__uid') . " name=" . $obj->getValue('name') . "\n";
}

echo "\n=== Kronolith ===\n";
require_once '/srv/www/mail-profissional/source/kronolith/lib/Application.php';
Horde_Registry::appInit('kronolith', array('cli' => true));
$registry->setAuth($user, array());

// Kronolith_Driver_Sql::backgroundColor() reads $GLOBALS['calendar_manager']
// unconditionally on every event construction; the real one
// (Kronolith::initialize()) drags in permission/auth checks and external
// calendar sources (holidays, remote subscriptions) we don't need for a
// plain data export. Stub it instead - we don't care about display colors.
$GLOBALS['calendar_manager'] = new class {
    public function getEntry($type, $id) { return false; }
};

$kShares = $injector->getInstance('Kronolith_Factory_Shares')->create($injector);
$kShare = $kShares->getShare($kronolithShareName);
echo "Share found: " . $kShare->get('name') . " (owner=" . $kShare->get('owner') . ")\n";

$kDriver = Kronolith::getDriver('Sql', $kronolithShareName);
$events = $kDriver->listEvents(null, null, array('cover_dates' => false));
$count = 0;
foreach ($events as $day => $dayEvents) { $count += count($dayEvents); }
echo "Events: $count\n";

echo "OK\n";
