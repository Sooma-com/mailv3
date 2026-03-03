# Elasticsearch Integration Specification

## Purpose

Defines how the plugin communicates with Elasticsearch, including
connection management, query construction, field mapping, and
result processing.

## Requirements

### Requirement: Elasticsearch Connection

The system SHALL connect to Elasticsearch using the official PHP client
(elastic/elasticsearch-php) with HTTP Basic Authentication.

#### Scenario: Successful connection

- GIVEN valid Elasticsearch endpoint and credentials in the plugin configuration
- WHEN the plugin needs to query logs
- THEN it establishes a connection using the configured endpoint and credentials
- AND uses HTTP Basic Auth for authentication

#### Scenario: Connection failure

- GIVEN invalid or unreachable Elasticsearch configuration
- WHEN the plugin attempts to query logs
- THEN a user-friendly error message is displayed
- AND no stack trace or credentials are exposed to the user

### Requirement: Index Configuration

The system SHALL query a single configurable Elasticsearch index.

#### Scenario: Configured index used for all queries

- GIVEN an index name configured in the plugin settings
- WHEN any log query is executed
- THEN the query targets only the configured index

### Requirement: Outbound Query Strategy

The system SHALL implement a two-phase query strategy for outbound
message tracing.

#### Scenario: Phase 1 — Message-ID lookup

- GIVEN a Message-ID to trace
- WHEN phase 1 executes
- THEN the plugin queries for documents where postfix.message-id OR
  rspamd.message-id equals the target Message-ID
- AND extracts all distinct (host.hostname, postfix.queueid) pairs
  from the results

#### Scenario: Phase 2 — Full log retrieval by queue-id pairs

- GIVEN a set of (host.hostname, postfix.queueid) pairs from phase 1
- WHEN phase 2 executes
- THEN the plugin queries for all documents matching any of those pairs
- AND returns results sorted by @timestamp ascending

### Requirement: Inbound Query Strategy

The system SHALL implement a query strategy for inbound message search
that filters by sender, recipient, and time window.

#### Scenario: Initial inbound query

- GIVEN a sender address, the logged-in user's address, and a time range
- WHEN the inbound search executes
- THEN the plugin queries for documents where postfix.kv.to matches
  the logged-in user's address AND postfix.from matches the sender
  AND @timestamp falls within the specified range

#### Scenario: Expansion after delivery found

- GIVEN initial inbound results that contain delivery entries
  (postfix.status = "sent" or similar)
- WHEN (host.hostname, postfix.queueid) pairs can be extracted
- THEN the plugin performs a phase 2 query identical to the outbound strategy
  to gather all related log entries

#### Scenario: No expansion when delivery refused

- GIVEN initial inbound results that show only refusal (e.g., milter-reject)
  with no successful delivery entries
- WHEN no (host.hostname, postfix.queueid) pairs yield further results
- THEN only the initial query results are returned

### Requirement: Field Mapping

The system SHALL use the following Elasticsearch fields for log retrieval
and display.

#### Scenario: Core fields retrieved per log entry

- GIVEN any log query
- WHEN results are returned
- THEN each entry includes at minimum: @timestamp, host.hostname, message
- AND where available: postfix.queueid, postfix.message-id, postfix.from,
  postfix.kv.to, postfix.status, postfix.kv.relay, postfix.kv.dsn,
  postfix.kv.delay, postfix.kv.delays, postfix.service,
  rspamd.action, rspamd.message-id, rspamd.score.value,
  rspamd.score.threshold

### Requirement: Result Ordering

The system SHALL return log entries sorted by timestamp in ascending order.

#### Scenario: Chronological result ordering

- GIVEN a set of log entries retrieved from Elasticsearch
- WHEN results are presented to the user
- THEN they are sorted by @timestamp in ascending order

### Requirement: TLS/SSL Support

The system SHALL support connecting to Elasticsearch over HTTPS, including
the ability to skip certificate verification for self-signed certificates.

#### Scenario: Self-signed certificate

- GIVEN an Elasticsearch endpoint using a self-signed TLS certificate
- WHEN the plugin configuration allows skipping certificate verification
- THEN the connection succeeds without certificate validation errors
