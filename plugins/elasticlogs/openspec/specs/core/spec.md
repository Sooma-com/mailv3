# Core Specification

## Purpose

Defines the core behavior of the Elasticlogs plugin: how users search for
message delivery logs, how results are assembled from Elasticsearch, and
how access control is enforced.

## Requirements

### Requirement: Outbound Message Log Search

The system SHALL allow users to retrieve delivery logs for outbound messages
by providing a Message-ID.

#### Scenario: Search by Message-ID from mail view

- GIVEN a logged-in user viewing a sent message
- WHEN the user initiates a log search for that message
- THEN the plugin reads the Message-ID header from the message
- AND queries Elasticsearch for all log entries matching that Message-ID
- AND collects all (hostname, queue-id) pairs from the results
- AND queries all log entries matching any of those (hostname, queue-id) pairs
- AND returns the combined set of log entries sorted chronologically

#### Scenario: No logs found for Message-ID

- GIVEN a logged-in user searching for an outbound message
- WHEN no log entries match the provided Message-ID
- THEN the plugin displays a message indicating no logs were found

### Requirement: Inbound/Outbound message search by sender and recipients

The system SHALL allow users to search for delivery logs of inbound and outbound messages
by providing an email address and a time window. The email address is to be matched against 
message sender and recipients fields

#### Scenario: Successful search with delivered message

- GIVEN a logged-in user searching for messages
- WHEN the user provides an email address and a time range
- THEN the plugin queries for log entries where either the message sender
  matches the email address or one of the message recipients match the email address
- AND if delivery entries are found, collects (hostname, queue-id) pairs
- AND queries all log entries matching those (hostname, queue-id) pairs
- AND filters messages related to the logged-in user, where the logged-in user's email
  matches either the sender or one of the recipients
- AND returns the combined set of log entries sorted chronologically

#### Scenario: Inbound search for refused message

- GIVEN a logged-in user searching for inbound messages
- WHEN matching log entries exist but delivery was refused (e.g., by rspamd)
- THEN the plugin returns whatever log entries were found for the initial query
- AND no further (hostname, queue-id) expansion is performed

#### Scenario: No matching entries

- GIVEN a logged-in user searching for messages
- WHEN no log entries match the sender, recipient, and time range
- THEN the plugin displays a message indicating no logs were found

### Requirement: Default Time Window

The system SHALL use a default time window of 24 hours for inbound searches.

#### Scenario: Default time range applied

- GIVEN a user opening the inbound search form
- WHEN no custom time range has been specified
- THEN the time window defaults to the last 24 hours

### Requirement: Multi-Hop Message Tracing

The system SHALL trace messages across multiple mail servers by following
the globally unique Message-ID across server hops.

#### Scenario: Message traverses multiple servers

- GIVEN a message that is processed by more than one mail server
- WHEN each server assigns a different queue-id but preserves the Message-ID
- THEN the plugin discovers all (hostname, queue-id) pairs via the Message-ID
- AND retrieves log entries from all servers involved in processing

### Requirement: Rspamd Log Correlation

The system SHALL include rspamd log entries when retrieving message logs.

#### Scenario: Rspamd entry correlated via Message-ID

- GIVEN a message processed by rspamd
- WHEN the rspamd log entry contains a message-id (in rspamd.message-id)
  matching the message being traced
- THEN the rspamd log entry is included in the results

#### Scenario: Message-ID present in either postfix or rspamd field

- GIVEN a log entry where postfix.message-id is null but rspamd.message-id
  is populated (or vice versa)
- THEN the non-null value is used for message-id matching

### Requirement: Access Control

The system MUST restrict log visibility so that users can only see logs
for messages where they are the sender or a recipient.

#### Scenario: User is the sender

- GIVEN a logged-in user whose email address matches postfix.from
- WHEN log entries are retrieved for a message
- THEN the entries are visible to the user

#### Scenario: User is a recipient

- GIVEN a logged-in user whose email address appears in postfix.kv.to
- WHEN log entries are retrieved for a message
- THEN the entries are visible to the user

#### Scenario: User is neither sender nor recipient

- GIVEN a logged-in user whose email address is neither the sender nor
  a recipient of a message
- WHEN the user attempts to view logs for that message
- THEN no log entries are returned

### Requirement: Result Export

The system SHALL allow users to download log results as a plain text file.

#### Scenario: Download log dump

- GIVEN a user viewing log search results
- WHEN the user requests a download
- THEN a TXT file is generated containing the raw log lines
- AND the file is offered for download

### Requirement: Single Email Address Per User

The system SHALL identify each user by exactly one email address, derived
from the Roundcube login session. Alias support is not required.

#### Scenario: User identity determination

- GIVEN a logged-in Roundcube user
- WHEN the plugin determines the user's email address
- THEN it uses the session username as the sole email identity
