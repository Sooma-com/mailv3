## Context

The specs have been updated to rename search modes from outbound/inbound
to message-id/sender-recipient. The code still uses the old terminology
everywhere: PHP method names, radio button values, HTML element ids,
localization keys, JS branching logic, and the access control check in
`search_outbound()` which only verifies `postfix.from`. This change
brings the code in line with the specs.

## Goals / Non-Goals

**Goals:**

- Rename all outbound/inbound references in code to message-id/sender-recipient
- Update access control to check both sender and recipient fields
- Keep all existing functionality working identically

**Non-Goals:**

- Implementing sender/recipient search backend
- CSS or template changes
- Changing the AJAX endpoint name (`search`)

## Decisions

### Decision: Rename radio values and element ids

Radio button values change from `outbound`/`inbound` to
`message-id`/`sender-recipient`. HTML element ids change from
`elasticlogs-outbound-fields`/`elasticlogs-inbound-fields` to
`elasticlogs-message-id-fields`/`elasticlogs-sender-recipient-fields`.
The JS mode-switching logic and AJAX parameter building update to
match the new values.

### Decision: Rename localization keys

| Old key | New key | EN text |
|---|---|---|
| `search_outbound` | `search_message_id` | By Message-ID |
| `search_inbound` | `search_sender_recipient` | By sender/recipient |
| `sender` | `sender_recipient` | Sender/Recipient |

The old keys are removed. The PHP `render_searchform()` method and
any JS references update to use the new keys.

### Decision: Rename PHP method

`search_outbound()` becomes `search_by_message_id()`. The dispatch
in `action_search()` changes from `$mode === 'outbound'` to
`$mode === 'message-id'`.

### Decision: Access control checks both sender and recipient

The access control block in `search_by_message_id()` currently only
checks `postfix.from`. It will be updated to also check `postfix.kv.to`
against the logged-in user's email. If any phase 1 result has either
field matching, access is granted.

## Risks / Trade-offs

**[Risk] Stale cached JS** — Users with cached JS may still send
`_mode=outbound`. The backend should handle unknown modes gracefully
(it already returns empty results for unrecognized modes).

## Migration Plan

- No database or configuration changes needed
- Direct code replacement, no backwards-compatibility shim
