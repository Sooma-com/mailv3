# Horde/IMP → Roundcube data migration: overview

This is the entry point for the migration specification. It covers scale, the
recommended architecture, user-identity mapping, and the cross-cutting
decisions that both the contacts and calendar migrations depend on. Field-level
detail lives in:

- [01-contacts.md](01-contacts.md) — Turba (addressbook) → Roundcube contacts
- [02-calendar.md](02-calendar.md) — Kronolith (calendar) → xcalendar plugin

All source citations below are paths relative to
`/home/sergio/Projects/Sooma/Profissional/webmail-horde/source` (Horde) or
`/home/sergio/Projects/Sooma/Profissional/webmail-roundcube` (Roundcube), as
inspected on 2026-09-16.

## 1. Systems involved

| | Host | Notes |
|---|---|---|
| Horde/IMP DB (source, read-only) | `10.3.1.132` / `mail_gratuito`, user `horde` | Live production data. **Never write to this database.** |
| Horde source code | `/home/sergio/Projects/Sooma/Profissional/webmail-horde/source` | The app's own `config/turba`, `config/kronolith` are broken symlinks to a production path (`/srv/www/mail-profissional/config/...`) not present on this machine; a working copy of that config tree exists at the sibling `config/` directory and was used for the attribute-map research below. |
| Roundcube DB (target, test) | `10.5.2.44` / `roundcube_gratuito`, user `roundcube` | Test install. Currently 4 users, all core tables (`contacts`, `contactgroups`, `xcalendar_events`, ...) empty — safe to experiment against. |
| Roundcube source code | this repository | Calendar is provided by a **custom in-house plugin, `plugins/xcalendar`** — not the stock Roundcube "calendar" plugin. Its schema is CalDAV-flavored (sync tokens, scheduling objects, per-attendee response tokens). |

## 2. Scale

| | Count |
|---|---|
| Distinct Turba addressbook owners (`turba_objects.owner_id`) | 219,166 |
| Turba addressbook shares (`turba_sharesng`) | 303,112 (some owners have >1 book) |
| Turba contact rows (`turba_objects`) | 5,348,012 (100% `object_type='Object'`; no `'Group'`/distribution-list rows exist in the current data, though the schema and code support them) |
| Kronolith calendars (`kronolith_sharesng`, distinct `calendar_id` in use) | 453 |
| Kronolith event rows (`kronolith_events`) | 1,270 |

Calendar usage is far lower than addressbook usage. Both are multi-tenant
across several domains (clix.pt, portugalmail.pt, aeiou.pt, oninet.pt,
kanguru.pt, ...), each historically with its own Horde per-domain config
(see the recent `1c128b743` commit on this repo's `production` branch, "Add
per-domain config for correio.aeiou.pt, correio.portugalmail.pt and
webmail.clix.pt"). None of that per-domain *config* affects the data-level
conversion described here (the `turba_objects`/`kronolith_events` schema and
encoding is identical across domains); it only matters for which IMAP/SMTP
host a migrated Roundcube `users` row should point at.

Given the size (5.3M contacts, 219K mailboxes) versus the tiny number of
Roundcube accounts that exist at any given time, **migration must be scoped
per-mailbox**, run either lazily (e.g. triggered the first time a user logs
into the new system) or in batches (e.g. one domain at a time), never as a
single monolithic pass over the whole `turba_objects`/`kronolith_events`
tables.

## 3. Recommended architecture: two-phase pipeline via intermediate files

Horde and Roundcube are two independent, incompatible PHP application
frameworks (different autoloaders, global registries, DB abstraction layers).
They cannot be bootstrapped in the same PHP process, and hand-decoding their
internal encodings independently is both effort-intensive and risky (Kronolith
in particular stores attendees as **nested PHP `Serializable` objects**, not
plain arrays — see [02-calendar.md](02-calendar.md) §2.1). Both frameworks
already ship working, exact converters to/from standard formats:

- **Turba → vCard 3.0**: `Turba_Driver::tovCard()`
  (`turba/lib/Driver.php:1265` onward) — handles name composition, `TYPE=`
  params, base64 photo encoding, charset flags, etc.
- **Kronolith → iCalendar 2.0**: `Kronolith_Event::toiCalendar()`
  (`kronolith/lib/Event.php:654` onward) and, per whole calendar,
  `Kronolith_Api::exportCalendar()` (`kronolith/lib/Api.php:957-1010`) — handles
  `RRULE`, `EXDATE`, `RECURRENCE-ID`, `VALARM`, `ATTENDEE`/`ORGANIZER`, etc.
- Roundcube's own vCard parser (`rcube_vcard`,
  `program/lib/Roundcube/rcube_vcard.php`) already reads standard vCard 3.0
  text and is what `rcube_contacts` uses internally.
- The xcalendar plugin's own ICS importer, `Event::importEvents()`
  (`plugins/xcalendar/program/Event.php:520-559`), already reads standard
  iCalendar text (via Sabre VObject) and drives the same save path the UI
  uses.

**Recommended pipeline:**

1. **Export phase** (PHP script bootstrapped inside the Horde application,
   modeled on Horde's own CLI scripts): for a given mailbox (username +
   domain), produce one vCard file per addressbook and one iCalendar file per
   calendar, using the exporters above. Also emit a small JSON sidecar per
   mailbox capturing metadata the standard formats don't carry losslessly
   (addressbook/calendar display names and colors, which book/calendar is the
   user's default, distribution-list membership by UID — see the two
   per-domain specs for exactly what's needed).
2. **Import phase** (PHP script bootstrapped inside Roundcube via
   `program/include/clisetup.php`, the same pattern used by
   [bin/indexcontacts.sh](../../bin/indexcontacts.sh),
   `bin/deluser.sh`, `bin/msgimport.sh`): resolve or create the target
   `rcube_user`, set it as the active user, then feed the vCard/iCalendar
   files through `rcube_contacts::insert()` and
   `Event::importEvents()`/`EventData` respectively.

This keeps all format-specific knowledge inside the code that already
implements it correctly, and confines the migration script itself to
orchestration: which mailbox, which files, which Roundcube records to
create/update, and bookkeeping for idempotency (§5).

Both per-domain specs document, in addition to this file-based path, the exact
column-level encodings — needed both to validate the intermediate files and
because a handful of things (group membership resolution, the
"skip-vs-modify" distinction for recurrence exceptions, default-calendar
detection) aren't fully carried by plain vCard/iCalendar and need to be
sourced from the DB columns directly, or written into the JSON sidecar during
export.

## 4. User identity mapping

Horde has **no local user table** for this install — `horde_users` is empty,
authentication is external (LDAP/Redis; see the `404584230` commit,
"reset_password: Rewrite to accept LDAP/Redis backends"). The addressbook and
calendar ownership is expressed purely through `Horde_Share`:

- `turba_sharesng.share_owner` / `kronolith_sharesng.share_owner` — the Horde
  login, which for this install **is the user's full email address**
  (e.g. `ypaulo@clix.pt`), confirmed by sampling both tables.
- Turba's `turba_objects.owner_id` is a *separate* string that usually (for a
  user's default/personal addressbook) equals that same login, but for
  secondary addressbooks equals the addressbook's own internal share key
  instead — see [01-contacts.md](01-contacts.md) §4 for the exact resolution
  algorithm. Kronolith's `calendar_id` is **always** the calendar's internal
  share key, never the login — see [02-calendar.md](02-calendar.md) §6.

On the Roundcube side, `users.username` + `users.mail_host` is the account
key (`SQL/postgres.initial.sql:19-30`), and `username` is also expected to be
(or derive) the mail login (`rcube_user::get_username()`,
`program/lib/Roundcube/rcube_user.php:94-123`). Sampling the test DB confirms
`username` is stored as the full email address here too (e.g.
`sergio.carvalho@portugalmail.pt`), matching Horde's convention.

**Mapping rule:** for a Horde login `user@domain`, resolve/create the
Roundcube account via `rcube_user::query('user@domain', $mail_host)`, falling
back to `rcube_user::create()` if it doesn't exist yet (standard Roundcube
behavior on first IMAP login). `$mail_host` must come from whatever
per-domain IMAP host mapping this Roundcube install already uses for that
domain (see the per-domain plugin config, e.g. `plugins/sooma/config.inc.php`)
— **please confirm the exact domain → `mail_host` table to use**, since it
isn't visible from the two databases alone.

## 5. Idempotency and cross-reference bookkeeping

Neither `contacts` nor `xcalendar_events` has a column exposing the source
system's stable identifier (Turba's `object_uid`, Kronolith's `event_uid`) —
Roundcube's vCard/vevent text has it buried inside a text blob (`UID:` line),
not indexed. To make the migration **safely re-runnable** (skip records
already migrated, resolve group-membership and recurrence cross-references
after IDs change), I'd like to add one small accessory table to the
Roundcube test database:

```sql
CREATE TABLE horde_migration_map (
    source_type  varchar(16)  NOT NULL,   -- 'contact' | 'contact_group' | 'calendar' | 'event'
    source_uid   varchar(255) NOT NULL,   -- turba object_uid / event_uid / share_name
    user_id      integer      NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    target_id    integer      NOT NULL,   -- contacts.contact_id / contactgroups.contactgroup_id / xcalendar_calendars.id / xcalendar_events.id
    migrated_at  timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (source_type, source_uid, user_id)
);
```

**I will tell you before creating this** (and it's trivial to drop once the
real migration is complete and verified) — flagging it now per your
instructions, since it's the one schema addition the scripts will need beyond
the existing tables.

## 6. Out of scope by default (needs your confirmation)

- **Horde ACL groups** (`horde_groups`/`horde_groups_members`) — the generic
  Horde permissions system used e.g. to share an addressbook with a group of
  users. Unrelated to Turba distribution-list contacts. Not needed unless you
  also want to migrate sharing ACLs (Roundcube's core addressbook has no
  sharing concept at all; the xcalendar plugin does via
  `xcalendar_calendars_shared`, keyed by attendee/collaborator e-mail rather
  than Horde group).
- **Kronolith resource calendars** (`kronolith_sharesng` rows with
  `attribute_calendar_type = 2`, i.e. `Kronolith::SHARE_TYPE_RESOURCE` —
  meeting rooms/equipment) — these are organization-wide objects, not part of
  any one mailbox. Confirm if resources need migrating at all, and if so,
  where they should land in xcalendar (which has no resource-booking concept
  visible in the schema you gave me access to).
- **Kronolith free/busy cache** (`kronolith_storage.vfb_serialized`) — pure
  cache, fully derivable from event data; skip unconditionally.
- **Tags** — both Turba contacts and Kronolith events support tagging via a
  shared subsystem that, in this install, is backed by tables named
  `rampage_*` (`rampage_objects`, `rampage_tags`, `rampage_tagged`, ...;
  `rampage_types` lists `calendar`/`event`/`contact`/`task`/`note`). There are
  1,745 tagged contacts and 1,267 tagged events in the live data — not
  negligible. Neither Roundcube's core addressbook nor the xcalendar plugin
  has a general-purpose tag list (xcalendar events have a single `category`
  string, matched against a small configured list — see
  [02-calendar.md](02-calendar.md) §4). Decide whether tags should be dropped,
  folded into `category` (lossy — only one tag could survive per event), or
  something else.
- **Calendar/contact file attachments** — checked: `horde_vfs` (Horde's
  generic file-storage backend, which Kronolith/Turba would use for any
  attachment) contains only 3 rows total, all internal session bookkeeping
  (`.horde/core/psession_data`). **No real attachments exist in this data
  set** — nothing to migrate here.

## 7. Known fidelity gaps (not avoidable, just documented)

- **Modified recurring occurrences.** Kronolith fully supports a single
  edited instance of a recurring series (`event_baseid` +
  `event_exceptionoriginaldate`, exported as a `RECURRENCE-ID` VEVENT). The
  xcalendar plugin's save path has **no column for `RECURRENCE-ID`** — an
  incoming VEVENT with `RECURRENCE-ID` is parsed but silently not persisted as
  a linked override. The plugin only supports whole-occurrence removal
  (`xcalendar_events_removed` / `EXDATE`). The migration must flatten a
  modified occurrence into a **standalone, non-recurring event** (with a new
  UID) plus an exclusion of the original date on the master series. See
  [02-calendar.md](02-calendar.md) §3 for the exact algorithm. This is a
  one-way, unavoidable loss of "linked to series" semantics — flagging it so
  it's a documented decision, not a surprise.
- **Turba's single-valued e-mail.** This Horde install's `localsql` backend
  config maps only one `email` column (multi-email `emails`/`homeEmail`/
  `workEmail` attributes are commented out of the field map) — so any
  contact that once had multiple e-mails already only has one surviving in
  `turba_objects` today. This is a pre-existing Horde-side limitation, not
  something the migration introduces or can recover.
- **xcalendar `category` vs. Horde tags/keywords** — see §6 above.

## 8. Open questions

1. Domain → Roundcube `mail_host` mapping — where should the migration script
   read this from?
2. Confirm scope/approach for: Horde ACL groups, resource calendars, tags
   (drop / fold into category / other), and the recurrence-exception
   flattening approach in §7.
3. Migration trigger model — lazy (on first login to the new system, e.g.
   hooked into `rcube_user::create()`/login) vs. batch (admin-run, one domain
   or mailbox list at a time)? This affects whether the script is a `bin/`
   CLI tool, a plugin hook, or both.
4. Secondary Turba addressbooks (the ~like 15% of owners who have more than
   one) — merge all of a user's contacts into their single Roundcube
   addressbook (Roundcube core only supports one SQL source per user by
   default), using contact groups to preserve which book a contact came from?
   Or is a different scheme wanted?
5. OK to add the `horde_migration_map` bookkeeping table described in §5 to
   the test database for prototyping? I'll drop it again whenever you'd like.
