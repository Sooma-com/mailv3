# Delta for Search Form

## ADDED Requirements

### Requirement: Search All Toggle for Support Agents

The search form MUST render a "Search all logs" checkbox for users
who are support agents. The checkbox MUST NOT be rendered for regular
users.

#### Scenario: Support agent sees the toggle

- GIVEN a logged-in user who is a support agent
- WHEN the elasticlogs search form is rendered
- THEN a checkbox labeled "Search all logs" (localized) is visible
- AND it is unchecked by default

#### Scenario: Regular user does not see the toggle

- GIVEN a logged-in user who is not a support agent
- WHEN the elasticlogs search form is rendered
- THEN no "Search all logs" checkbox is present in the DOM

#### Scenario: Search all parameter sent via AJAX

- GIVEN a support agent who has checked the "Search all logs" checkbox
- WHEN the search form is submitted
- THEN the AJAX request includes a `_search_all` parameter set to 1

#### Scenario: Search all parameter not sent when unchecked

- GIVEN a support agent who has not checked the "Search all logs"
  checkbox
- WHEN the search form is submitted
- THEN the AJAX request does not include a `_search_all` parameter
