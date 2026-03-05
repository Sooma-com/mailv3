## Why

To integrate the log search with the rest of the Roundcube UI (e.g.
context menus on messages or contacts), the search form needs to accept
GET parameters that pre-populate fields and trigger an automatic search.
This is the prerequisite for linking from the mail view or address book
to the log search page.

## What Changes

- Read GET parameters (`message_id`, `sender_recipient`, `date_from`,
  `date_to`) in JavaScript on page load and populate the corresponding
  form fields
- If `message_id` is set, select the message-id search mode
- If `sender_recipient` is set (and `message_id` is not), select the
  sender-recipient search mode
- If both are set, prefer message-id mode
- If neither is set, default to sender-recipient mode (changed from
  the current default of message-id)
- If either `message_id` or `sender_recipient` is set, automatically
  submit a search request on page load
- Change the PHP form default: the sender-recipient radio is checked
  by default and its fields are initially visible (message-id fields
  hidden)

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `search-form`: Form fields can be pre-populated via GET parameters;
  default mode changes to sender-recipient; auto-submit on pre-populated
  parameters

## Impact

- **Modified files**: `elasticlogs.php` (default checked radio and
  field visibility), `js/elasticlogs.js` (GET parameter reading,
  field population, mode selection, auto-submit)
- **No new dependencies**
- **No backend changes**

## Non-goals

- Creating the context menu hooks in mail view or address book
  (separate changes)
- Server-side parameter validation (the backend already validates
  POST parameters on search submission)
