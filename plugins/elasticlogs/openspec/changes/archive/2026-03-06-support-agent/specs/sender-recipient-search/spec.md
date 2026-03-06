# Delta for Sender/Recipient Search

## MODIFIED Requirements

### Requirement: Access Control for Sender/Recipient Search

The plugin MUST filter phase 1 results to entries where the logged-in
user is the sender or a recipient, unless the user is a support agent
who has opted to search all logs.

#### Scenario: Support agent bypasses access control

- GIVEN a support agent performing a sender/recipient search with
  search-all enabled
- WHEN phase 1 returns entries
- THEN the access control filter (array_filter by user email) is skipped
- AND all phase 1 entries proceed to phase 2 expansion

#### Scenario: Server-side role verification

- GIVEN a non-support-agent user who forges a `_search_all` parameter
- WHEN the search action processes the request
- THEN the server verifies the user's role before honoring the parameter
- AND access control filtering is enforced normally
