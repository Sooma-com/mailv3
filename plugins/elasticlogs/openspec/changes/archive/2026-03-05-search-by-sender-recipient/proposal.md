## Why

The sender/recipient search mode currently returns empty results — the
backend stub was never replaced. Users need to be able to search for
message logs by providing an email address and a time window, covering
cases where they don't have a Message-ID (e.g. investigating whether a
message was sent/received).

## What Changes

- Implement `search_by_sender_recipient()` in `elasticlogs.php`:
  1. Phase 1: ES|QL query filtering by `postfix.from` OR `postfix.kv.to`
     matching the target email address, within the given time range
  2. Access control: filter results to entries where the logged-in user
     is the sender or a recipient
  3. Phase 2: collect (hostname, queueid) pairs from phase 1 results
     and expand via a second ES|QL query
  4. Return sorted results to the frontend
- Wire `action_search()` to dispatch `sender-recipient` mode to the
  new method
- Remove debug override (`$access_granted = true`) from
  `search_by_message_id()`

## Capabilities

### New Capabilities

- `sender-recipient-search`: ES|QL query strategy for searching by
  email address and time window, with access control and queue-id
  expansion

### Modified Capabilities

- `search-form`: The search action for sender-recipient mode now
  performs a real query instead of returning empty results

## Impact

- **Modified files**: `elasticlogs.php` (new method, action dispatch)
- **No new dependencies**
- **No UI changes** — the frontend already handles results from both modes

## Non-goals

- Pre-populating the sender/recipient field from a contact context
  (future change)
- Text export / download of results
- Human-readable event summaries
