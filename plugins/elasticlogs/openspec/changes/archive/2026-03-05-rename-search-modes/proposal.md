## Why

The search modes were originally named "outbound" and "inbound", implying
a direction-based model. This doesn't match the actual use cases: a user
either has a Message-ID and wants an exact trace, or they have an email
address and want a fuzzy search within a time window. The code still uses
the old outbound/inbound terminology — radio values, variable names, HTML
ids, localization keys, JS branching, and the access control logic only
checks `postfix.from` (sender). The specs have already been updated to the
new model; the code must follow.

## What Changes

- Rename radio button values from `outbound`/`inbound` to
  `message-id`/`sender-recipient` in the search form (PHP + JS)
- Rename HTML element ids and PHP variables from
  `outbound-fields`/`inbound-fields` to
  `message-id-fields`/`sender-recipient-fields`
- Rename the `search_outbound`/`search_inbound` localization keys to
  `search_message_id`/`search_sender_recipient` and update label text
- Rename the `sender` localization key to `sender_recipient` and update
  label text
- Rename the PHP method `search_outbound()` to `search_by_message_id()`
- **Update access control**: check both `postfix.from` and
  `postfix.kv.to` against the logged-in user (not just sender)

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `message-id-search`: Access control now checks both sender
  (`postfix.from`) and recipient (`postfix.kv.to`), not just sender
- `search-form`: Radio values, field ids, and localization keys
  change from outbound/inbound to message-id/sender-recipient

## Impact

- **Modified files**: `elasticlogs.php` (method rename, access control,
  form rendering), `js/elasticlogs.js` (radio values, element ids),
  `localization/en_US.inc`, `localization/pt_PT.inc` (key renames and
  label updates)
- **No new dependencies**
- **No breaking API changes** — this is a UI rename with no external
  consumers

## Non-goals

- Implementing the sender/recipient search backend (separate change)
- Changing the search action endpoint name or AJAX protocol
- Any changes to CSS or template files
