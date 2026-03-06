# Delta for Core

## MODIFIED Requirements

### Requirement: Access Control

The system MUST restrict log visibility so that users can only see logs
for messages where they are the sender or a recipient. Support agents
MAY optionally bypass this restriction when they choose to search all
logs. This access rule applies uniformly to all search modes.

#### Scenario: Support agent searches all logs

- GIVEN a logged-in user who is a configured support agent
- AND the user has opted to search all logs
- WHEN log entries are retrieved for a search
- THEN access control filtering is skipped
- AND all matching log entries are returned regardless of sender
  or recipient

#### Scenario: Support agent searches own logs

- GIVEN a logged-in user who is a configured support agent
- AND the user has not opted to search all logs
- WHEN log entries are retrieved for a search
- THEN normal access control applies
- AND only entries where the user is sender or recipient are returned

#### Scenario: Regular user unaffected

- GIVEN a logged-in user who is not a configured support agent
- WHEN the user performs any search
- THEN access control applies as before
- AND the search-all option is not available

## ADDED Requirements

### Requirement: Support Agent Role

The system MUST recognize a configurable set of users as support
agents who can optionally bypass access control restrictions.

#### Scenario: User is a support agent

- GIVEN a logged-in user whose username appears in the configured
  support-agents list (case-insensitive)
- WHEN the plugin evaluates the user's role
- THEN the user is identified as a support agent

#### Scenario: User is not a support agent

- GIVEN a logged-in user whose username does not appear in the
  configured support-agents list
- WHEN the plugin evaluates the user's role
- THEN the user is identified as a regular user
