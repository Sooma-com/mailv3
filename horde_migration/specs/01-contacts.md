# Contacts migration: Turba → Roundcube addressbook

See [00-overview.md](00-overview.md) for architecture, user mapping, and
scope decisions this spec depends on.

## 1. Horde/Turba storage

### 1.1 Tables

- **`turba_objects`** — one row per contact *or* per distribution list
  (`object_type = 'Object'` vs `'Group'`; only `'Object'` exists in the
  current data, but `'Group'` is fully supported by the schema/code and must
  be handled). Primary key `object_id` (locally-generated random string, see
  §1.5) — **not** the portable identifier; use `object_uid` for that.
- **`turba_sharesng`** — one row per addressbook (a `Horde_Share`). Columns
  used by the migration: `share_name` (internal key), `share_owner` (Horde
  login/email — the account the book belongs to), `attribute_name`
  (display title, e.g. "Address book of jane@clix.pt"), `attribute_params`
  (PHP-`serialize()`d array — see §1.4 for what's inside).

### 1.2 Field map (turba_objects → logical attribute)

The column list is fixed by the live `turba_objects` schema; the *logical
attribute name* each column represents (used by vCard export and the UI) is
defined by this install's `turba/config/backends.php` (`$cfgSources['localsql']['map']`),
not hard-coded in PHP. The relevant mappings:

| Column(s) | Attribute | Notes |
|---|---|---|
| `object_id` | `__key` | local PK, not portable |
| `owner_id` | `__owner` | see §4 for resolution |
| `object_type` | `__type` | `'Object'` or `'Group'` |
| `object_members` | `__members` | only for Groups, see §3 |
| `object_uid` | `__uid` | **globally unique, portable identifier** — `Horde_Support_Guid`, format `"turba:<source>:<uid>"` when used for Horde history logging |
| `object_nameprefix`, `object_firstname`, `object_middlenames`, `object_lastname`, `object_namesuffix` | `namePrefix`, `firstname`, `middlenames`, `lastname`, `nameSuffix` | composed into vCard `N`/`FN` |
| `object_alias`, `object_nickname` | `alias`, `nickname` | |
| `object_bday`, `object_anniversary` | `birthday`, `anniversary` | **plain string, format `YYYY-MM-DD`** (`strftime('%Y-%m-%d')`); sentinel `0000-00-00` means "empty", not a real date — check for it |
| `object_photo` + `object_phototype`, `object_logo` + `object_logotype` | `photo`/`photo_orig`, `logo` | raw binary bytes; `*type` is a genuine **MIME type string** (e.g. `image/jpeg`), used as the vCard `TYPE=` parameter and base64-encoded at the vCard boundary only |
| `object_home{street,pob,city,province,postalcode,country}` | `homeStreet`, ... | also composable into a single `homeAddress` string (`format`/`parse` in config) — simplest to read the split columns directly |
| `object_work{street,pob,city,province,postalcode,country}` | `workStreet`, ... | same pattern |
| `object_other{street,pob,city,province,postalcode,country}` | `otherStreet`, ... | same pattern |
| `object_email` | `email` | **single-valued in this install** (see [00-overview.md](00-overview.md) §7) |
| `object_homeemail`, `object_workemail` | `homeEmail`, `workEmail` | present as columns; confirm whether populated (config comments suggest these were disabled at one point — verify with a `count(*) where object_homeemail is not null` before relying on them) |
| `object_homephone`, `object_homephone2`, `object_workphone`, `object_workphone2`, `object_cellphone`, `object_carphone`, `object_radiophone`, `object_companyphone`, `object_fax`, `object_homefax`, `object_pager`, `object_assistantphone` | assorted phone types | map to vCard `TEL;TYPE=...` |
| `object_imaddress`, `object_imaddress2`, `object_imaddress3` | IM handles | see rcube_vcard IM handling, §2.2 — no protocol tag stored alongside these in Turba's schema, so protocol must default to something generic (e.g. Jabber) or be dropped to a generic "im" field on the Roundcube side |
| `object_title`, `object_role`, `object_company`, `object_department` | job info | → vCard `TITLE`/`ROLE`/`ORG` |
| `object_manager`, `object_assistant`, `object_spouse` | relations | → Roundcube X- vCard extensions (`X-MANAGER`/`X-ASSISTANT`/`X-SPOUSE`, see §2.2 — happen to match 1:1) |
| `object_notes` | `notes` | free text |
| `object_url`, `object_freebusyurl` | `website`, free/busy URL | freebusy URL has no Roundcube contact equivalent — drop, or append to notes |
| `object_pgppublickey`, `object_smimepublickey` | PGP/S-MIME public keys | ASCII-armored text; Roundcube core contacts have no dedicated key field (that's the Enigma plugin's domain, keyed differently) — likely drop, or append to notes if you want them preserved somewhere |
| `object_tz`, `object_geo` | timezone/geo | no Roundcube contact equivalent — drop |
| `object_yomifirstname`, `object_yomilastname` | phonetic name (Japanese) | no Roundcube equivalent — drop unless needed |

Composite fields (`name`, `homeAddress`, `workAddress`, `otherAddress`) are
computed from the split columns via `sprintf`-style format strings in Turba's
config, not stored — always read the individual split columns above rather
than trying to re-derive/parse a composite.

### 1.3 Distribution lists (`object_type = 'Group'`)

A "Group" is an ordinary `turba_objects` row (can carry name/notes/etc. like
any contact) whose `object_members` column holds a **PHP `serialize()`'d
indexed array of member identifiers** (`turba/lib/Object/Group.php:96-108`).
Each element is one of:

- a bare `object_id` — a member **in the same addressbook** (same
  `turba_objects` share); or
- `"<source>:<object_id>"` (colon-delimited) — a member in a **different**
  configured addressbook/source (rare; only relevant if cross-book references
  exist in this dataset — worth a quick `SELECT` to check for `:` inside
  `object_members` before assuming it never happens).

**These `object_id` values are only valid within this Horde install** and
must be re-resolved on import. Recommended resolution:

1. During export, for each Group row, resolve every member id to that
   member's stable `object_uid` (a same-book lookup:
   `SELECT object_uid FROM turba_objects WHERE object_id = ?`), and write the
   list of member UIDs into the JSON sidecar for that addressbook (see
   [00-overview.md](00-overview.md) §3) rather than relying on vCard
   `X-ADDRESSBOOKSERVER-MEMBER` round-tripping.
2. During import, after all `'Object'` rows have been inserted into
   Roundcube and their `object_uid → contact_id` mapping recorded (see the
   bookkeeping table in [00-overview.md](00-overview.md) §5), create one
   `contactgroups` row per Turba Group and populate `contactgroupmembers` by
   resolving each member UID through that mapping. Since currently **no**
   `'Group'` rows exist in the production data sampled, this path can be
   built and tested once a book with a distribution list is found, or
   synthesized for a test.

### 1.4 Addressbook ownership (`turba_sharesng` / `owner_id` resolution)

This is the one genuinely tricky part of the Turba side. `owner_id` in
`turba_objects` is **not** a share id — it's whatever string ended up in
`unserialize(turba_sharesng.attribute_params)['name']` for the corresponding
share:

- **Default/personal addressbook** (created automatically): `params['name']`
  is set to the Horde login itself
  (`Turba::getConfigFromShares()`, `turba/lib/Turba.php:602-613`) — so
  **`owner_id` literally equals the user's login/email** for their main book.
  Confirmed by sampling: `turba_sharesng.attribute_params` for e.g. share_id 4
  is `a:3:{s:6:"source";s:8:"localsql";s:7:"default";b:1;s:4:"name";s:28:"manuel.costa@portugalmail.pt";}`
  — `name` = `manuel.costa@portugalmail.pt` = `share_owner`.
- **Secondary addressbooks** (user-created via "Create Address Book"):
  `params['name']` defaults to the **share's own key** (`share_name`) instead
  (`turba/lib/Turba.php:553-561`) — so for these, `owner_id == share_name`,
  *not* the username.

**Resolution algorithm per addressbook:**

```
for each row in turba_sharesng:
    params = unserialize(attribute_params)
    book_owner_login = share_owner                  -- who this book belongs to
    book_display_name = attribute_name
    is_default = (params['name'] == share_owner)     -- true for the user's main book
    contacts_in_book = SELECT * FROM turba_objects WHERE owner_id = params['name']
```

219,166 distinct `owner_id` values exist against 303,112 shares — i.e. most
users have exactly one book, some (~15%, e.g. `jpcp@aeiou.pt` with 22 shares)
have several. See [00-overview.md](00-overview.md) open question 4 for how
multiple books per user should land in Roundcube (which only supports one SQL
addressbook per user out of the box).

Horde ACL groups (`horde_groups`) are unrelated to any of the above — they're
the generic Horde permissions system, not Turba distribution lists. Out of
scope per [00-overview.md](00-overview.md) §6.

### 1.5 Identifiers

- `object_id` — locally auto-generated (`Horde_Support_Randomid`), **not
  portable**, only used within the same Horde install (as the PK, and inside
  `object_members`).
- `object_uid` — globally unique (`Horde_Support_Guid`), stable, portable.
  **Use this as the migration's join key** for idempotency bookkeeping
  (matches the `source_uid` column in the accessory table proposed in
  [00-overview.md](00-overview.md) §5).

### 1.6 Tags (out of scope by default)

Contact tags are **not** stored in `turba_objects` — they live in the shared
`rampage_*` tagging tables, keyed by `object_uid` and type `contact`
(1,745 tagged contacts exist in the live data). See
[00-overview.md](00-overview.md) §6.

### 1.7 Existing exporter to reuse

`Turba_Driver::tovCard($object, '3.0')` (`turba/lib/Driver.php:1265` onward)
already builds a correct vCard 3.0 (`N`/`FN`/`ORG`/`TEL;TYPE=...`/
`EMAIL;TYPE=...`/`BDAY`/`PHOTO;ENCODING=b;TYPE=...`/`X-ANNIVERSARY`/etc.) for
a single contact. Driving this from a small Horde-bootstrapped CLI script,
once per contact in a book, is the recommended export mechanism (see
[00-overview.md](00-overview.md) §3) — it already handles the encoding edge
cases (8-bit charset flags, base64 photo, composite name parts) that would
otherwise need to be reimplemented.

## 2. Roundcube storage

### 2.1 Tables

```
users(user_id PK, username, mail_host, ..., UNIQUE(username, mail_host))
contacts(contact_id PK, user_id FK, changed, del, name, email, firstname, surname, vcard, words)
contactgroups(contactgroup_id PK, user_id FK, changed, del, name)
contactgroupmembers(contactgroup_id FK, contact_id FK, created, PK(contactgroup_id, contact_id))
```

Contacts and groups are always **private per Roundcube user** — there is no
book-level sharing concept in core Roundcube (unlike Turba's per-book
`Horde_Share`). `contactgroups` has **no `type` column** — a "group" and a
"distribution list" are the same thing in Roundcube; it's a flat
`name` + membership join table, nothing more
(`SQL/postgres.initial.sql:195-221`; confirmed no migration ever added a type
column).

### 2.2 `vcard` is the source of truth — `name`/`email`/`firstname`/`surname`/`words` are derived

Confirmed in `program/lib/Roundcube/rcube_contacts.php`:

- On **read**, `convert_db_data()` (lines 724–742): if `vcard` is non-empty,
  it's parsed and **its fields override the raw SQL columns**
  (`$vcard->get_assoc() + $sql_arr`). The plain columns are only a fallback
  for when `vcard` is empty.
- On **write**, `convert_save_data()` (lines 747–820) rebuilds the vCard from
  scratch every save (`$vcard->reset()` then `set()` per field,
  `$vcard->export(false)`), and derives:
  - `words` — a search index: `rcube_utils::normalize_string()` applied to
    every value of every field in `fulltext_cols` (`name, firstname, surname,
    middlename, nickname, jobtitle, organization, department, maidenname,
    email, phone, address, street, locality, zipcode, region, country,
    website, im, notes`), concatenated.
  - `email` (the plain column) — always overwritten to mirror whatever ended
    up in the vCard's `EMAIL` properties (lines 810–814), not taken as-is
    from input.
  - `name`, `firstname`, `surname` — taken from the input field array
    directly.
- `insert()` (lines 642–682) / `update()` (lines 692–719) are plain
  parameterized SQL once `convert_save_data()` has built the row.

**Practical rule for the migration: do not hand-build the vCard text or
`words` column.** Call `rcube_contacts::insert($save_data)` with the
*decoded field array* (the same shape `rcube_vcard::get_assoc()` produces —
e.g. `firstname`, `surname`, `email:home` => [...]`, `phone:mobile` =>
[...]`), and let Roundcube derive everything else. This also means the
Horde-side vCard text (from `tovCard()`) should be **parsed back into a field
array with `rcube_vcard`** (Roundcube's own parser) before calling `insert()`
— i.e. the "intermediate format" is standard vCard text, but the *Roundcube
import step* re-parses it into the field-array shape `rcube_contacts`
expects, rather than writing the `vcard` DB column directly.

### 2.3 vCard field/type map (`rcube_vcard.php`)

| Roundcube field | vCard property | Notes |
|---|---|---|
| `phone` | `TEL` | subtype from `TYPE=`, e.g. `phone:home`, `phone:mobile` (`IPHONE`/`CELL`→mobile), `phone:work,fax` (`WORK,FAX`) |
| `email` | `EMAIL` | subtype `email:home`, `email:work`, etc. |
| `address` | `ADR` | structured: component 2=street, 3=locality, 4=region, 5=zipcode, 6=country; subtype `address:home`/`address:work` (`BUSINESS`→work) |
| `birthday` | `BDAY` | |
| `website` | `URL` | |
| `notes` | `NOTE` | |
| `jobtitle` | `TITLE` | |
| `photo` | `PHOTO` | `;ENCODING=b` inline base64 if not an `http:` URL reference |
| `im:<protocol>` | `X-JABBER`, `X-ICQ`, `X-MSN`, `X-AIM`, `X-YAHOO`, `X-SKYPE`/`X-SKYPE-USERNAME` | legacy X- properties only, no vCard 4 `IMPP` support — Turba's single unlabeled `object_imaddress*` columns will need a default protocol assigned (e.g. treat as Jabber, or as a generic note) since Turba doesn't record which IM protocol each address uses |
| `department` | `X-DEPARTMENT` | |
| `gender` | `X-GENDER` | no Turba source column — n/a |
| `maidenname` | `X-MAIDENNAME` | no Turba source column — n/a |
| `anniversary` | `X-ANNIVERSARY` | matches Turba's `object_anniversary` directly |
| `assistant` | `X-ASSISTANT` | matches Turba's `object_assistant` |
| `manager` | `X-MANAGER` | matches Turba's `object_manager` |
| `spouse` | `X-SPOUSE` | matches Turba's `object_spouse` |
| `groups` | `CATEGORIES` | **not** used for Roundcube group membership — `rcube_contacts` explicitly strips this before persisting (`$vcard->set('groups', null)`, line 767–768); group membership only lives in the `contactgroups`/`contactgroupmembers` tables, populated separately |

vCard output is version **3.0**.

### 2.4 User resolution

`rcube_user::query($username, $mail_host)` /
`rcube_user::create($username, $mail_host)`
(`program/lib/Roundcube/rcube_user.php:587-614`, `:624+`) — see
[00-overview.md](00-overview.md) §4. The migration script must call
`$rcmail->user = $user;` before using `rcube_contacts` (which reads the
current user's ID internally) — see the CLI bootstrap pattern in
[00-overview.md](00-overview.md) §3.

## 3. Field-by-field mapping summary

| Turba (`turba_objects`) | Roundcube field (via `rcube_contacts::insert()`) |
|---|---|
| `object_nameprefix`/`object_firstname`/`object_middlenames`/`object_lastname`/`object_namesuffix` | `prefix`, `firstname`, `middlename`, `surname`, `suffix` (composed also into `name`) |
| `object_nickname` | `nickname` |
| `object_bday` (`YYYY-MM-DD`, skip if `0000-00-00`) | `birthday` |
| `object_anniversary` (same format/sentinel) | `anniversary` |
| `object_photo` (prefer `object_photoorig` if non-empty) | `photo` (raw bytes; `rcube_vcard` base64-encodes) |
| `object_home*` columns | `address:home` (structured) |
| `object_work*` columns | `address:work` (structured) |
| `object_other*` columns | `address:other` → Roundcube has no native "other" address type; fold into `address:home` additional entry, or drop — decide with you |
| `object_email` | `email:home` (single value) |
| `object_home{phone,phone2,fax}` | `phone:home`, `phone:home2`, `phone:homefax` |
| `object_work{phone,phone2}` | `phone:work`, `phone:work2` |
| `object_cellphone` | `phone:mobile` |
| `object_fax` | `phone:workfax` |
| `object_pager`, `object_carphone`, `object_radiophone`, `object_companyphone`, `object_assistantphone` | `phone:pager`/etc. (map to nearest available subtype, or a generic `phone:other`) |
| `object_title` | `jobtitle` |
| `object_role` | no direct Roundcube field — fold into `jobtitle` or `notes` |
| `object_company` | `organization` |
| `object_department` | `department` |
| `object_manager` | `manager` |
| `object_assistant` | `assistant` |
| `object_spouse` | `spouse` |
| `object_imaddress`, `object_imaddress2`, `object_imaddress3` | `im:jabber` (default protocol assignment, see §2.3) |
| `object_notes` | `notes` |
| `object_url` | `website:homepage` |
| `object_pgppublickey`, `object_smimepublickey`, `object_freebusyurl`, `object_tz`, `object_geo`, `object_yomifirstname`, `object_yomilastname` | no target field — drop (confirm with you first) |
| `object_uid` | not written to any Roundcube column directly, but used as the `source_uid` key in the bookkeeping table (see [00-overview.md](00-overview.md) §5) |

## 4. Conversion algorithm (per mailbox)

1. Resolve target `rcube_user` (create if needed) — see §2.4.
2. For each `turba_sharesng` row owned by this user (§1.4), in order
   (default book first):
   a. For each `'Object'` row in that book: build the Roundcube field array
      per §3, call `rcube_contacts::insert()`, record
      `(object_uid → contact_id)` in the bookkeeping table.
   b. For each `'Group'` row in that book: create a `contactgroups` row
      (name = the group's `object_firstname`/whatever Turba used as its
      display name), resolve `object_members` per §1.3, call
      `add_to_group()` for each resolved member.
   c. If this is not the user's default book, decide (per
      [00-overview.md](00-overview.md) open question 4) whether to also tag
      its contacts with a Roundcube group named after the book, so the
      original grouping isn't lost when everything lands in one addressbook.
3. Skip any row whose `object_uid` is already present in the bookkeeping
   table for this user (idempotent re-run).

## 5. Edge cases to handle explicitly

- **Date sentinel** `0000-00-00` in `object_bday`/`object_anniversary` means
  "no value" — must not be imported as a literal year-0 date.
- **Empty contacts** — sampling showed real rows in `turba_objects` with
  every field blank except `object_uid` (e.g. `owner_id='clixabuEnlXSlqyepkZskbB'`
  rows with no name/email/phone at all). Roundcube's `validate()`
  (`rcube_contacts.php` lines 614–632) requires a name or email; decide
  whether to skip these, or insert them with a placeholder name.
- **Photo/logo MIME type** — use `object_phototype`/`object_logotype`
  directly as the image MIME type; prefer `object_photoorig` over
  `object_photo` when present (avoids re-propagating a Turba-side resize).
- **Multiple addressbooks per owner** — see §1.4 and open question 4.
