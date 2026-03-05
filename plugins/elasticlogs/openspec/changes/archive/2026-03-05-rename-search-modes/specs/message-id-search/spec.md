# Delta for Message-ID Search

## MODIFIED Requirements

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
