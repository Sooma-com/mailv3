# Delta for Message-ID Search

## MODIFIED Requirements

### Requirement: Access Control for Message-ID Search

The plugin MUST verify that the logged-in user is the sender or a
recipient of the message before returning log entries, unless the
user is a support agent who has opted to search all logs.

#### Scenario: Support agent bypasses access control

- GIVEN a support agent performing a message-id search with search-all
  enabled
- WHEN phase 1 returns entries
- THEN access control is skipped
- AND the search proceeds directly to phase 2 regardless of sender
  or recipient fields

#### Scenario: Server-side role verification

- GIVEN a non-support-agent user who forges a `_search_all` parameter
- WHEN the search action processes the request
- THEN the server verifies the user's role before honoring the parameter
- AND access control is enforced normally
