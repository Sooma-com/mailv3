# Delta for Outbound Search

## ADDED Requirements

### Requirement: Phase 1 — Message-ID Lookup

The plugin MUST query Elasticsearch for log entries matching a given
Message-ID as the first phase of outbound search.

#### Scenario: Query by postfix.message-id

- GIVEN a Message-ID submitted by the user
- WHEN phase 1 executes
- THEN the plugin queries the configured index for documents where
  postfix.message-id equals the submitted Message-ID
- AND returns matching documents with at minimum @timestamp,
  host.hostname, postfix.queueid, postfix.from, and message fields

#### Scenario: No entries found for Message-ID

- GIVEN a Message-ID that does not exist in the logs
- WHEN phase 1 executes
- THEN an empty result set is returned to the frontend

### Requirement: Access Control for Outbound Search

The plugin MUST verify that the logged-in user is the sender of the
message before returning log entries.

#### Scenario: User is the sender

- GIVEN phase 1 returns entries where at least one has a postfix.from
  value matching the logged-in user's email address
- WHEN access control is checked
- THEN the search proceeds to phase 2

#### Scenario: User is not the sender

- GIVEN phase 1 returns entries but none have a postfix.from value
  matching the logged-in user's email address
- WHEN access control is checked
- THEN an empty result set is returned to the frontend
- AND phase 2 is not executed

### Requirement: Phase 2 — Queue-ID Expansion

The plugin MUST collect (host.hostname, postfix.queueid) pairs from
phase 1 results and query for all log entries matching those pairs.

#### Scenario: Expand by queue-id pairs

- GIVEN phase 1 returned entries with host.hostname and
  postfix.queueid fields populated
- WHEN phase 2 executes
- THEN the plugin queries for all documents where any
  (host.hostname, postfix.queueid) pair matches
- AND appends the results to the phase 1 result set

#### Scenario: No queue-id pairs found

- GIVEN phase 1 returned entries but none have both host.hostname
  and postfix.queueid populated
- WHEN phase 2 would execute
- THEN only the phase 1 results are returned

### Requirement: Result Deduplication and Sorting

The plugin MUST deduplicate and chronologically sort the combined
results from both phases.

#### Scenario: Deduplicated and sorted results

- GIVEN results from phase 1 and phase 2 that may overlap
- WHEN the results are merged
- THEN duplicate entries (by Elasticsearch document ID) are removed
- AND the remaining entries are sorted by @timestamp ascending
- AND returned to the frontend

### Requirement: Result Size Limit

The plugin MUST limit the number of documents returned per query phase.

#### Scenario: Query size capped

- GIVEN any Elasticsearch query in phase 1 or phase 2
- WHEN the query executes
- THEN no more than 1000 documents are requested per phase
