# Calendar migration: Kronolith → xcalendar plugin

See [00-overview.md](00-overview.md) for architecture, user mapping, and
scope decisions this spec depends on.

## 1. Horde/Kronolith storage

### 1.1 Tables

- **`kronolith_events`** — one row per event (or per event *occurrence
  exception*, see §3). PK `event_id` (locally-generated, not portable);
  `event_uid` is the portable/stable identifier.
- **`kronolith_sharesng`** — one row per calendar (a `Horde_Share`), same
  generic mechanism as Turba's `turba_sharesng`. Columns used: `share_name`
  (= `kronolith_events.calendar_id`), `share_owner`, `attribute_name`
  (display title), `attribute_color`.
- **`kronolith_resources`** — legacy/superseded table (migration
  `24_kronolith_upgrade_resourcestoshares.php` moved resource definitions
  into `kronolith_sharesng` rows with an added `attribute_calendar_type = 2`
  i.e. `Kronolith::SHARE_TYPE_RESOURCE`). Treat as dead; out of scope per
  [00-overview.md](00-overview.md) §6 regardless.
- **`kronolith_storage`** (`vfb_serialized`) — free/busy cache only, skip
  unconditionally (§00-overview §6).

### 1.2 Column encodings

| Column | Format | Details |
|---|---|---|
| `event_attendees` | **PHP `Serializable`-object serialization**, not a plain array | A `Kronolith_Attendee_List` wrapping `Kronolith_Attendee` objects, each serializing to `{'u'=>user, 'e'=>email, 'p'=>role, 'r'=>response, 'n'=>name}` (`kronolith/lib/Attendee.php:216-225`). The raw text looks like `C:23:"Kronolith_Attendee_List":N:{...C:17:"Kronolith_Attendee":M:{...}}` — a nested "class-wrapped" serialize form. **A legacy pre-v5 format may also appear**: a plain `a:N:{email => {attendance, response, name}}` array — `Kronolith_Event_Sql::fromDriver()` checks `is_object(unserialize(...))` to distinguish the two (`kronolith/lib/Event/Sql.php:132-146`). Decoding this outside PHP is impractical; use the export-via-PHP approach in [00-overview.md](00-overview.md) §3 rather than parsing this column directly. |
| `event_resources` | plain `serialize()` of `resource_id => {attendance, response, name, calendar}` | `resource_id` = a `kronolith_sharesng.share_id`. Out of scope (§00-overview §6). |
| `event_alarm_methods` | plain `serialize()` of `{'notify'=>{...}, 'mail'=>{...}, 'popup'=>{...}}` | Notification channel config, not needed if xcalendar's own alarm delivery (popup/email, see §2.7) is used instead. |
| `event_keywords` | column exists but is **dead code** — never read or written anywhere in the current Kronolith codebase | ignore |
| `event_exceptions` | **plain comma-separated `YYYYMMDD` date strings** (no serialization) | `implode(',', $recurrence->getExceptions())` / `explode(',', ...)` (`Event/Sql.php:264`, `:115-117`). These are dates **removed** from the recurrence (both plain deletions and dates that have a corresponding modified-occurrence row, see §3). |
| `object_bday`-equivalent n/a | — | (not applicable here, contacts-only) |

### 1.3 Recurrence

`event_recurtype` — integer constant (`framework/Date/lib/Horde/Date/Recurrence.php:33-61`):

| Value | Constant | Meaning |
|---|---|---|
| 0 | `RECUR_NONE` | not recurring |
| 1 | `RECUR_DAILY` | every N days |
| 2 | `RECUR_WEEKLY` | every N weeks, on given weekday(s) |
| 3 | `RECUR_MONTHLY_DATE` | every N months, same day-of-month |
| 4 | `RECUR_MONTHLY_WEEKDAY` | every N months, same Nth weekday |
| 5 | `RECUR_YEARLY_DATE` | every N years, same date |
| 6 | `RECUR_YEARLY_DAY` | every N years, same day-of-year |
| 7 | `RECUR_YEARLY_WEEKDAY` | every N years, same Nth weekday of month |
| 8 | `RECUR_MONTHLY_LAST_WEEKDAY` | every N months, *last* occurrence of that weekday |

(Live data sample: types 0, 2, 3, 5 are the ones actually in use — 1,257
non-recurring, 6 weekly, 2 monthly-date, 5 yearly-date, out of 1,270 total
events.)

- `event_recurinterval` — the "every N" multiplier.
- `event_recurdays` — **only for `RECUR_WEEKLY`**: a bitmask of
  `Horde_Date::MASK_*` (`SUNDAY=1, MONDAY=2, TUESDAY=4, WEDNESDAY=8,
  THURSDAY=16, FRIDAY=32, SATURDAY=64`), OR'd for multiple days.
- `event_recurenddate` — real end datetime, or sentinel
  `'9999-12-31 23:59:59'` meaning "no end" (confirmed in live data — the
  sampled yearly events all carry this sentinel).
- `event_recurcount` — occurrence count (alternative/independent to an end
  date).

**Use Horde's own converter rather than reimplementing this**:
`Horde_Date_Recurrence::toRRule20($calendar)`
(`framework/Date/lib/Horde/Date/Recurrence.php:1226-1303`) produces an exact
RFC 5545 `RRULE` value string (e.g. `FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE`),
which is exactly the format xcalendar's `repeat_rule` column expects (§2.2) —
this is precisely what `Kronolith_Event::toiCalendar()` already calls
internally, reinforcing the export-via-existing-code approach.

### 1.4 Recurrence exceptions vs. modified occurrences — the important distinction

Two different things share the `event_exceptions` mechanism:

- **Deleted occurrence** (no replacement): a date present in
  `event_exceptions` with no other row referencing it. Exported as an
  `EXDATE` in iCalendar.
- **Modified occurrence** (a single instance rescheduled/edited): a
  **separate row** in `kronolith_events`, with its own `event_id`/`event_uid`,
  where:
  - `event_baseid` = the `event_uid` of the original recurring series
    (**not** `event_id`), and
  - `event_exceptionoriginaldate` = the datetime of the un-modified
    occurrence being overridden.

  Exported as a distinct `VEVENT` carrying `RECURRENCE-ID` (with its `UID`
  rewritten to match the base series' UID in the ICS output), and the base
  event's exception list has that date removed from its plain `EXDATE`s
  during export (since it's represented by the override VEVENT instead).

**This is the one place the two calendar systems don't line up** — see §3
below for how the xcalendar plugin needs it flattened.

### 1.5 Other event fields

- `event_alarm` — plain integer, **minutes before start** (positive = before;
  0/absent = no alarm). Per-user default comes from the `default_alarm`
  Horde preference when not explicitly set on the event.
- `event_private` — plain boolean int (`0`/`1`).
- `event_status` — integer (`kronolith/lib/Kronolith.php:26-30`): `0`=NONE,
  `1`=TENTATIVE, `2`=CONFIRMED, `3`=CANCELLED, `4`=FREE (Kronolith-specific,
  not a real iCalendar `STATUS`; represents a "free/available" marker rather
  than tentative/confirmed/cancelled).
- Attendee `role` (inside the serialized blob): `Kronolith::PART_*`
  (`REQUIRED=1, OPTIONAL=2, NONE=3, IGNORE=4`); attendee `response`:
  `Kronolith::RESPONSE_*` (`NONE=1, ACCEPTED=2, DECLINED=3, TENTATIVE=4`).

### 1.6 Calendar ownership and default calendar

`calendar_id` in `kronolith_events` is **always**
`kronolith_sharesng.share_name` (the calendar's internal random key) — unlike
Turba, it is **never** the raw username, even for a user's own default
calendar (confirmed: `kronolith_sharesng` sample shows e.g. share_name
`a-2DMSdgLOlCbcn6QJNU30_` for `share_owner = sergio.carvalho@portugalmail.pt`
— no correspondence to the login string). Ownership is via
`share_owner` only.

There is **no schema flag on `kronolith_sharesng` reliably marking "this is
the user's default calendar."** The actual default pointer is a **Horde
preference**: `horde_prefs` row with `pref_scope='kronolith'`,
`pref_name='default_share'`, `pref_value` = the calendar's `share_name` as a
raw (non-serialized) byte string — confirmed by sampling (e.g.
`sergio.carvalho@portugalmail.pt` → `pref_value` decodes to
`a-2DMSdgLOlCbcn6QJNU30_`, matching that user's only calendar's share_name).
**Read this preference per user to identify their default calendar**;
`Kronolith::getDefaultCalendar()` (`kronolith/lib/Kronolith.php:1164-1188`)
falls back to "any calendar the user owns" if the pref is missing or stale.

## 2. Roundcube xcalendar plugin storage

### 2.1 Tables

```
xcalendar_calendars(id PK, user_id FK, type, url, name, description, timezone,
                     bg_color, tx_color, enabled, default_event_visibility,
                     created_at, modified_at, removed_at, properties)
xcalendar_events(id PK, user_id, calendar_id FK, uid, title, location, description,
                  url, start, end, all_day, repeat_rule, repeat_end,
                  use_calendar_colors, bg_color, tx_color, busy, visibility,
                  priority, category, attachments, vevent, created_at,
                  modified_at, removed_at, has_attendees,
                  timezone_start, timezone_end, vevent_uid)
xcalendar_events_custom(user_id, event_id, use_calendar_colors, bg_color, tx_color)  -- per-viewer color override, not needed for migration
xcalendar_attendees(event_id, calendar_id, email, name, code, organizer, role,
                     hidden, can_see_attendees, notify, status, guests,
                     comment, created_at, responded_at, user_id)
xcalendar_alarms(id PK, user_id, event_id, event_end, alarm_number, alarm_units,
                  snooze, alarm_position, alarm_time, absolute_datetime,
                  alarm_type, processing_started)
xcalendar_events_removed(id PK, day, event_id, removed_at, removed_by)   -- excluded single occurrences
xcalendar_calendars_shared, xcalendar_changes, xcalendar_published,
xcalendar_scheduling_objects, xcalendar_synced                          -- CalDAV sync/sharing bookkeeping, not relevant to a one-time data migration
```

`xcalendar_calendars.type` constants (`plugins/xcalendar/program/Calendar.php:19-24`):
`LOCAL=1, HOLIDAY=2, GOOGLE=3, CALDAV=4, BIRTHDAY=5`. Migrated calendars
should be created with `type = LOCAL`.

Every Roundcube user already gets one auto-created default calendar
("Novo calendário", `type=1`) the first time they're provisioned — confirmed
in the test DB (all 4 test users already have exactly this row). Decide
whether the user's Kronolith default calendar should be imported *into* this
existing row (rename it, keep its `id`) or as an additional calendar (leaving
"Novo calendário" empty/unused) — recommend the former when the user has
exactly one Kronolith calendar, to avoid a redundant empty calendar
appearing in the UI.

### 2.2 `vevent`/`repeat_rule` — derived vs. authoritative

Confirmed in `plugins/xcalendar/program/EventData.php`:

- **`repeat_rule` is authoritative and is a full standard RRULE value
  string** (e.g. `FREQ=WEEKLY;BYDAY=MO,WE;COUNT=10`) — written by
  `encodeRRule()` (lines 838–924, `implode(";", $array)`), read by
  `decodeRRule()`, and fed directly into
  `\Sabre\VObject\Recur\RRuleIterator($event['repeat_rule'], $startDate)`
  (`program/Event.php:361`) to expand occurrences. **This is exactly what
  Horde's `toRRule20()` (§1.3) produces** — copy it through essentially
  verbatim. When importing external ICS, the plugin preserves the
  **original** incoming RRULE string as-is rather than re-deriving it
  (`saveToDb()` lines 214–225) — so feeding Horde's RRULE straight through an
  ICS import path (§2.9) keeps it byte-for-byte intact.
- **`vevent` (the VEVENT text blob) is regenerated from the structured
  columns on every save** (`saveToDb()`, lines 196–296 — the vevent text is
  built *last*, from just-saved column data, via `createVEvent()` at line
  275) and is **not** used as a read source except as a one-time legacy
  fallback for pre-2020-10-15 rows missing `timezone_start`/`timezone_end`.
  **Do not treat vevent as something to hand-craft or preserve verbatim from
  Horde** — populate the structured columns and either call
  `EventData::createVEvent()`/`saveToDb()` (letting the plugin regenerate
  it), or use the ICS-import path (§2.9), which does this automatically.

### 2.3 Recurrence exceptions — no modified-occurrence support

**Only whole-occurrence exclusion is supported.** Recurring events are
expanded on the fly from the single `xcalendar_events` row
(`Event::getRepeatedEvents()`, `program/Event.php:339-387`, via
`Sabre\VObject\Recur\RRuleIterator`) — occurrences are never materialized as
separate rows. "Delete this one occurrence" is modeled by
`xcalendar_events_removed(day, event_id, ...)`
(`EventData::saveExcluded()`, lines 1553+).

On the *parsing* side, an incoming ICS `RECURRENCE-ID`/`EXDATE` is
recognized (`Event::vEventToDataArray()`, lines 1450–1455), but
**`recurrence_id` is not in the whitelist of persisted columns**
(`getSavableEventData()`, lines 1067–1088) — a modified-occurrence VEVENT
would have its override silently dropped if imported naively (only the
`EXDATE` side survives).

**Migration algorithm required:** for every Kronolith modified occurrence
(§1.4), do **not** pass its VEVENT through as a `RECURRENCE-ID` override.
Instead:

1. Ensure the master recurring event's exclusion list (`event_exceptions` /
   the eventual `xcalendar_events_removed` rows) includes the original date
   — this is already true on the Kronolith side (the override's date is
   removed from the base's plain-EXDATE list specifically because it's
   represented by the override).
2. Import the modified occurrence as a **new, independent, non-recurring**
   xcalendar event (fresh `uid`/`vevent_uid`, `repeat_rule = ''`), carrying
   whatever fields actually changed (its own `start`/`end`/`title`/etc.).

This is a one-way approximation (the modified instance is no longer "linked"
to its series in the UI) but is the only way to avoid silent data loss, since
the plugin has no column to preserve the link. Flagged as a fidelity gap in
[00-overview.md](00-overview.md) §7.

**Implemented** in `horde_migration/scripts/import-mailbox.php`
(`flatten_recurrence_overrides()`), and verified against a real mailbox
(`jlofernandes4@clix.pt`, 5 recurring series with 28 modified-occurrence rows
across them). Without this step, `Event::importEvents()` silently collapsed
every VEVENT sharing a UID onto one `xcalendar_events` row (confirmed: an
11-VEVENT family collapsed to 1 row, master's `RRULE` wiped out - see the
session that diagnosed this for exact numbers). With it: each override gets a
deterministic UID (`<original-uid>.flattened-<recurrence-id-value>`, so
re-imports stay idempotent), and the master's own re-exported `EXDATE` list
gets the override's original date injected if Kronolith's export didn't
already carry it - otherwise the recurring series would also generate a
phantom duplicate on top of the flattened occurrence.

### 2.4 `category`

Single free-text column (`VARCHAR(255)`, no FK/constraint — any string can be
stored). The UI's category picker only *highlights* a value if it
case-insensitively matches an entry in the configured `xcalendar_categories`
list (default: `Personal (#8B008B)`, `Work (#483D8B)`, `Family (#006400)`,
overridable in Roundcube config — `Event::getCategories()`,
`program/Event.php:1159-1192`). Kronolith event tags (§1, out of scope by
default) are the closest analog on the Horde side but are a *list*, not a
single value — if tags need preserving here, only one can survive per event
(see [00-overview.md](00-overview.md) §6).

### 2.5 Attachments

Not applicable — confirmed via `horde_vfs` (only 3 unrelated internal rows)
that no calendar attachments exist in this data set
([00-overview.md](00-overview.md) §6). If this ever changes, note that
`xcalendar_events.attachments` is a JSON array of
`{"path": "<encoded action URL>", "name", "size"}`, where the file itself
must be physically placed under the plugin's configured attachment directory
using its own encoded-URL convention (`Event::attachmentUrlToPath()`/
`Utils::encodeUrlAction()`, `program/Event.php:1214-1224` and upload flow
lines 567–635) — not a simple filesystem path.

### 2.6 Attendees

Columns and meaning (`plugins/xcalendar/program/EventData.php:1614-1676`):

| Column | Values |
|---|---|
| `status` | `0`=NEEDS-ACTION, `1`=ACCEPTED, `2`=DECLINED, `3`=TENTATIVE, `4`=DELEGATED |
| `role` | `0`=REQ-PARTICIPANT, `1`=OPT-PARTICIPANT, `2`=NON-PARTICIPANT, `3`=CHAIR |
| `code` | a random per-attendee secret token for "respond without login" email links — **generate fresh, don't try to preserve anything from Kronolith** |
| `guests` | additional/plus-one guest count (`X-NUM-GUESTS`) |

Kronolith → xcalendar status/role mapping (both are small closed enums,
straightforward numeric remap — Kronolith's `Kronolith::RESPONSE_*`/
`PART_*` values don't numerically coincide with xcalendar's, so an explicit
lookup table is needed, not a passthrough):

| Kronolith `response` | → xcalendar `status` |
|---|---|
| `RESPONSE_NONE` (1) | `0` NEEDS-ACTION |
| `RESPONSE_ACCEPTED` (2) | `1` ACCEPTED |
| `RESPONSE_DECLINED` (3) | `2` DECLINED |
| `RESPONSE_TENTATIVE` (4) | `3` TENTATIVE |

| Kronolith `role`(attendance) | → xcalendar `role` |
|---|---|
| `PART_REQUIRED` (1) | `0` REQ-PARTICIPANT |
| `PART_OPTIONAL` (2) | `1` OPT-PARTICIPANT |
| `PART_NONE` (3) | `2` NON-PARTICIPANT |
| `PART_IGNORE` (4) | — drop the attendee, or map to NON-PARTICIPANT |

**No email side effect from bulk import**: `xcalendar_attendees` rows are
plain SQL inserts via `EventData::saveAttendees()`
(`program/EventData.php:1493-1546`), which does **not** send mail. Actual
notification emails only fire from four specific call sites
(`Event::sendAttendeeEmailNotifications()` — the UI's drag/reschedule and
save-form actions, explicit remove/restore, and incoming CalDAV iTIP
processing). Confirmed that **`Event::importEvents()`, the plugin's own bulk
ICS-import API, never calls it** — so driving the migration through
`importEvents()` (§2.9) is safe and won't spam attendees with invitation
emails.

### 2.7 Alarms

Constants (`plugins/xcalendar/program/Event.php:20-24`):
`ALARM_BEFORE_START=0, ALARM_AFTER_START=1, ALARM_BEFORE_END=2,
ALARM_AFTER_END=3, ALARM_ABSOLUTE_TIME=4`; `alarm_type`: `0`=popup/DISPLAY,
`1`=EMAIL.

Kronolith's `event_alarm` (minutes-before-start integer, §1.5) maps directly
to `alarm_position = ALARM_BEFORE_START (0)`, `alarm_number = event_alarm`,
`alarm_units = 'minutes'`, `alarm_type = 0` (popup) — Kronolith doesn't
distinguish alarm delivery channel per-event the way xcalendar's `alarm_type`
does (that's what `event_alarm_methods` was for, out of scope per
[00-overview.md](00-overview.md) §6), so default every migrated alarm to
popup/display.

For a **recurring** event's alarm, xcalendar stores one alarm row with
`event_end` set to the series' `repeat_end` and re-derives the next actual
firing occurrence live (`getAlarms()`,
`plugins/xcalendar/program/Event.php:796-905`) — no need to generate one
alarm row per occurrence.

### 2.8 `xcalendar_calendars.properties`

**JSON** (not serialized PHP) —
`CalendarData::decodeProperties()`/`encodeProperties()`
(`plugins/xcalendar/program/CalendarData.php:774-798`). For a
`type=LOCAL` calendar this is typically empty/`[]` (the only special key,
`caldav_password`, is for remote CalDAV subscriptions — n/a here).

### 2.9 Existing import path to reuse

`Event::importEvents(string $ics, int $calendarId)`
(`plugins/xcalendar/program/Event.php:520-559`) is a ready-made bulk ICS
import entry point: parses the ICS into one-or-more structured event arrays,
upserts each by UID (`vevent_uid`) within the target calendar, and persists
via the normal `EventData::save()` path. This is the recommended way to drive
the import (see [00-overview.md](00-overview.md) §3) — it produces correct
`vevent`/derived-column state for free, and (per §2.6) never sends attendee
notification emails. For events needing structured-field-level control
beyond what a straight ICS round-trip gives you (e.g. the flattened
modified-occurrence events from §2.3), drop down to constructing an
`EventData` object directly and calling `save()`.

## 3. Field-by-field mapping summary

| Kronolith (`kronolith_events`) | xcalendar (`xcalendar_events`) |
|---|---|
| `event_uid` | `vevent_uid` (and used as the ICS `UID` during the intermediate-file import) |
| `event_title` | `title` |
| `event_description` | `description` |
| `event_location` | `location` |
| `event_url` | `url` |
| `event_start`, `event_end` | `start`, `end` |
| `event_allday` | `all_day` |
| `event_timezone` | `timezone_start`/`timezone_end` |
| `event_recurtype`+`event_recurinterval`+`event_recurdays`+`event_recurenddate`+`event_recurcount` | `repeat_rule` (RRULE string, via `toRRule20()`), `repeat_end` |
| `event_exceptions` (plain deletions only) | `xcalendar_events_removed` rows |
| `event_baseid`+`event_exceptionoriginaldate` (modified occurrence) | flattened into a standalone event, see §2.3 |
| `event_alarm` | one `xcalendar_alarms` row, see §2.7 |
| `event_private` | `visibility` column (confirm exact enum values in xcalendar source before implementing — schema shows a free varchar, samples show `'default'`/`'public'`; likely `private=1 → 'private'`, `private=0 → 'public'`, needs a quick source check) |
| `event_status` | `STATUS_FREE (4)` → `busy = 0`; all other statuses → `busy = 1` (recommended default logic — Kronolith's CONFIRMED/TENTATIVE/CANCELLED don't map cleanly onto xcalendar's simpler `busy` boolean; CANCELLED events might instead be worth excluding from migration entirely — confirm with you) |
| `event_attendees` (per attendee) | one `xcalendar_attendees` row each, per the status/role tables in §2.6 |
| — | `category` — only populated if migrating tags (out of scope by default, §00-overview §6) |
| `event_resources` | out of scope (§00-overview §6) |
| `event_keywords` | dead column, ignore |

## 4. Conversion algorithm (per mailbox)

1. Resolve target `rcube_user` (§00-overview §4); ensure the plugin's
   auto-created default calendar exists (it's created on user provisioning).
2. Read the Horde `default_share` preference for this user
   (`horde_prefs` where `pref_scope='kronolith'`, `pref_name='default_share'`)
   to identify their default Kronolith calendar (§1.6).
3. For each `kronolith_sharesng` row owned by this user
   (`attribute_calendar_type` not `= 2`/resource):
   a. If it's the user's default calendar and they have only one calendar,
      reuse/rename the existing "Novo calendário" `xcalendar_calendars` row;
      otherwise create a new one (`type=LOCAL`, `name` = `attribute_name`,
      `bg_color` = `attribute_color`).
   b. Export the calendar's non-exception, non-override events plus, for
      each modified-occurrence row, a separately-flattened event, as
      described in §2.3, into one ICS text (or drive `EventData` directly —
      either is fine as long as the flattening happens before anything
      reaches xcalendar).
   c. Call `Event::importEvents($ics, $calendarId)` (§2.9) to persist.
   d. Record `(event_uid → xcalendar event id)` in the bookkeeping table
      (`kronolith event_uid` is stable and portable, same convention as
      Turba's `object_uid`).
4. Skip any `event_uid` already present in the bookkeeping table for this
   user (idempotent re-run).

## 5. Edge cases to confirm with you

- Exact `xcalendar_events.visibility` enum and the private/public mapping
  (§3) — needs a quick look at the plugin's visibility-handling code before
  implementation; not fully confirmed by the research so far.
- Whether `STATUS_CANCELLED` (3) events should be migrated at all, or
  dropped outright.
- Default-calendar reuse-vs-create policy (§4 step 3a) when a user has
  multiple Kronolith calendars, none of which is obviously "the same as"
  the pre-existing empty xcalendar default.
