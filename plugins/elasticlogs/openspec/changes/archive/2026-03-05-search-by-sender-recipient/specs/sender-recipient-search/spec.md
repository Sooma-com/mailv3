# Delta for Sender/Recipient Search

## ADDED Requirements

### Requirement: Phase 1 — Sender/Recipient Lookup

The plugin MUST query Elasticsearch for log entries where the target
email address matches either the sender or recipient field, within
the specified time range, using ES|QL.

#### Scenario: Query by email address and time range

- GIVEN a target email address, a start date, and an end date
- WHEN phase 1 executes
- THEN the plugin sends an ES|QL query filtering where postfix.from
  or postfix.kv.to equals the target email address AND @timestamp
  falls within the date range, sorted by @timestamp ascending

#### Scenario: No entries found

- GIVEN a target email address and time range with no matching entries
- WHEN phase 1 executes
- THEN an empty result set is returned to the frontend

### Requirement: Access Control for Sender/Recipient Search

The plugin MUST filter phase 1 results to entries where the logged-in
user is the sender or a recipient.

#### Scenario: Entries where user is a party

- GIVEN phase 1 returns entries
- WHEN access control filtering is applied
- THEN only entries where postfix.from or postfix.kv.to matches the
  logged-in user's email address are retained

#### Scenario: No authorized entries

- GIVEN phase 1 returns entries but none involve the logged-in user
  as sender or recipient
- WHEN access control filtering is applied
- THEN an empty result set is returned to the frontend

### Requirement: Phase 2 — Queue-ID Expansion

The plugin MUST collect (host.hostname, postfix.queueid) pairs from
the access-controlled phase 1 results and expand via a second query.

#### Scenario: Expand by queue-id pairs

- GIVEN filtered phase 1 results with hostname and queueid fields
- WHEN phase 2 executes
- THEN the plugin sends a single ES|QL query combining the original
  email match condition with all (hostname, queueid) pair conditions
- AND the phase 2 result set replaces the phase 1 result set

#### Scenario: No queue-id pairs found

- GIVEN filtered phase 1 results without hostname/queueid pairs
- WHEN phase 2 would execute
- THEN only the phase 1 results are returned

### Requirement: Input Sanitization

The plugin MUST sanitize the target email address and date values
before interpolating them into ES|QL query strings.

#### Scenario: Email address sanitized

- GIVEN a target email address from the user
- WHEN the value is used in an ES|QL query
- THEN backslashes and double quotes are stripped from the value
