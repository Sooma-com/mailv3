# Delta for Search Form

## MODIFIED Requirements

### Requirement: Form Submission via AJAX

The search form MUST submit search parameters via AJAX to the server-side
search action, which now returns real results for sender/recipient mode.

#### Scenario: Sender/recipient search returns real results

- GIVEN the search action receives a sender-recipient mode request
- WHEN the target email matches entries in Elasticsearch within the
  time range
- AND the logged-in user is the sender or a recipient of at least
  one matching entry
- THEN real log entries are returned in the AJAX response
- AND the frontend renders them chronologically in the results area
