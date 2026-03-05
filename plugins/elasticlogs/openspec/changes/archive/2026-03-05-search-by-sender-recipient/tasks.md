## 1. PHP — Search Action Dispatch

- [x] 1.1 In `action_search()`: add `sender-recipient` mode dispatch to `search_by_sender_recipient()`
- [x] 1.2 Remove debug override `$access_granted = true` from `search_by_message_id()`

## 2. PHP — Sender/Recipient Search

- [x] 2.1 Implement `search_by_sender_recipient()`: read `_sender_recipient`, `_date_from`, `_date_to` from POST; validate non-empty
- [x] 2.2 Phase 1: ES|QL query filtering by (postfix.from == email OR postfix.kv.to == email) AND @timestamp within date range, sorted by @timestamp ASC
- [x] 2.3 Access control: filter results to entries where the logged-in user is sender (postfix.from) or recipient (postfix.kv.to)
- [x] 2.4 Collect distinct (host.hostname, postfix.queueid) pairs from filtered results
- [x] 2.5 Phase 2: ES|QL query combining email match condition OR with all (hostname, queueid) pairs; replaces phase 1 results
- [x] 2.6 Send results to frontend via `plugin.elasticlogs_search_response` command
- [x] 2.7 Wrap in try/catch with localized error handling

## 3. Verification

- [x] 3.1 Verify frontend renders sender/recipient search results correctly (no JS changes expected)
