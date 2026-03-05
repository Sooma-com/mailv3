# Delta for Search Form

## MODIFIED Requirements

### Requirement: Form Submission via AJAX

The search form MUST submit search parameters via AJAX to the server-side
search action.

#### Scenario: Outbound form submission

- GIVEN the user has entered a Message-ID in outbound mode
- WHEN the user clicks the search button
- THEN an AJAX POST is sent to the search action
- AND the request includes the search mode and the Message-ID value

#### Scenario: Inbound form submission

- GIVEN the user has filled in sender and time range in inbound mode
- WHEN the user clicks the search button
- THEN an AJAX POST is sent to the search action
- AND the request includes the search mode, sender address, start date,
  and end date

#### Scenario: Outbound search returns real results

- GIVEN the search action receives an outbound mode request
- WHEN the Message-ID matches entries in Elasticsearch
- AND the logged-in user is the sender
- THEN real log entries are returned in the AJAX response
- AND the frontend renders them chronologically in the results area

#### Scenario: Outbound search returns error

- GIVEN the search action receives an outbound mode request
- WHEN Elasticsearch is unreachable or returns an error
- THEN a localized error message is displayed to the user
