# Message-ID Search Specification

## Purpose

Defines the message-id log search behavior: the two-phase ES|QL
query strategy (Message-ID lookup, then queue-id expansion), access
control verifying the user is the sender or a recipient, result
sorting, and input sanitization.
## Requirements
### Requirement: Phase 1 — Message-ID Lookup

The plugin MUST query Elasticsearch for log entries matching a given
Message-ID as the first phase of message-id search, using ES|QL.

#### Scenario: Query by postfix.message-id

- GIVEN a Message-ID submitted by the user
- WHEN phase 1 executes
- THEN the plugin sends an ES|QL query to the configured index
  filtering where `postfix.message-id` equals the submitted Message-ID,
  sorted by @timestamp ascending
- AND the response is hydrated into associative arrays keyed by
  column name

#### Scenario: No entries found for Message-ID

- GIVEN a Message-ID that does not exist in the logs
- WHEN phase 1 executes
- THEN an empty result set is returned to the frontend

### Requirement: Access Control for Message-ID Search

The plugin MUST verify that the logged-in user is the sender or a
recipient of the message before returning log entries.

#### Scenario: User is the sender

- GIVEN phase 1 returns entries where at least one has a postfix.from
  value matching the logged-in user's email address
- WHEN access control is checked
- THEN the search proceeds to phase 2

#### Scenario: User is a recipient

- GIVEN phase 1 returns entries where at least one has a postfix.kv.to
  value matching the logged-in user's email address
- WHEN access control is checked
- THEN the search proceeds to phase 2

#### Scenario: User is neither sender nor recipient

- GIVEN phase 1 returns entries but none have a postfix.from or
  postfix.kv.to value matching the logged-in user's email address
- WHEN access control is checked
- THEN an empty result set is returned to the frontend
- AND phase 2 is not executed

### Requirement: Phase 2 — Queue-ID Expansion

The plugin MUST collect (host.hostname, postfix.queueid) pairs from
phase 1 results and query for all log entries matching those pairs,
combined with the original message-id condition.

#### Scenario: Expand by queue-id pairs

- GIVEN phase 1 returned entries with host.hostname and
  postfix.queueid fields populated
- WHEN phase 2 executes
- THEN the plugin sends a single ES|QL query with an OR clause
  combining the message-id condition and all (hostname, queueid) pairs
- AND the phase 2 result set replaces the phase 1 result set entirely
  (since it is a superset)

#### Scenario: No queue-id pairs found

- GIVEN phase 1 returned entries but none have both host.hostname
  and postfix.queueid populated
- WHEN phase 2 would execute
- THEN only the phase 1 results are returned

### Requirement: Result Sorting

The plugin MUST chronologically sort the results.

#### Scenario: Sorted results

- GIVEN results from either phase 1 only or phase 2
- WHEN the results are returned to the frontend
- THEN entries are sorted by @timestamp ascending (via ES|QL SORT)

### Requirement: Input Sanitization

The plugin MUST sanitize user-supplied values before interpolating
them into ES|QL query strings.

#### Scenario: Message-ID sanitized

- GIVEN a Message-ID value from the user
- WHEN the value is used in an ES|QL query
- THEN backslashes and double quotes are stripped from the value

