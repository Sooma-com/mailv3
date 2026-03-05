## Context

The plugin has a working message-id search mode backed by ES|QL queries.
The sender/recipient mode has a form that submits via AJAX but the
backend returns empty results. This change implements the real query
logic, following the same patterns established by `search_by_message_id()`.

## Goals / Non-Goals

**Goals:**

- Implement sender/recipient search with ES|QL
- Apply the same access control model (user must be sender or recipient)
- Expand results via queue-id pairs when delivery entries are found
- Return chronologically sorted results to the frontend

**Non-Goals:**

- Pre-population of the email field from external context
- Text export
- Loading state indicators

## Decisions

### Decision: Phase 1 query matches both sender and recipient fields

The initial ES|QL query filters for entries where `postfix.from` or
`postfix.kv.to` matches the target email address, within the user-
supplied time range:

```esql
FROM {index}
| WHERE (@timestamp >= "{date_from}" AND @timestamp <= "{date_to}")
    AND (postfix.from == "{email}" OR postfix.kv.to == "{email}")
| SORT @timestamp ASC
```

### Decision: Access control filters by logged-in user

After phase 1, results are filtered to entries where the logged-in
user is the sender (`postfix.from`) or recipient (`postfix.kv.to`).
This is necessary because the target email address may be a third
party — the user must still be a party to the message.

Unlike message-id search where access control is a gate (pass/fail
for the entire result set), sender/recipient search filters at the
entry level because the initial query may return entries for multiple
distinct messages, some of which may not involve the logged-in user.

### Decision: Phase 2 expands by queue-id pairs from filtered results

After access-control filtering, (hostname, queueid) pairs are
collected from the remaining entries and expanded via a second query,
following the same pattern as message-id search. The phase 2 query
includes both the queue-id pair conditions and the original email
match condition in an OR clause.

### Decision: Input sanitization via strtr

The target email address and date strings are sanitized using
`strtr()` to strip backslashes and double quotes, consistent with
the message-id search approach.

### Decision: Reuse existing patterns

The method follows the same structure as `search_by_message_id()`:
same `hydrate_response()` helper, same error handling, same response
format. No new helpers or abstractions needed.

## Risks / Trade-offs

**[Risk] Large result sets** — A broad time window with a common
email address could return many entries. ES|QL returns all matching
rows. Acceptable for v1.0; pagination can be added later.

**[Trade-off] Entry-level vs message-level access control** — We
filter individual entries rather than grouping by message. This means
a message where the user is neither sender nor recipient but which
shares a queue-id with an authorized message could leak entries in
phase 2. This is a minor edge case that is acceptable for v1.0.

## Migration Plan

- No configuration changes needed
- No database changes
- Rollback: revert to the stub that returns empty results
