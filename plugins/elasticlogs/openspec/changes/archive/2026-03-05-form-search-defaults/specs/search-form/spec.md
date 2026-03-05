# Delta for Search Form

## MODIFIED Requirements

### Requirement: Search Mode Selection

The search form MUST allow the user to switch between message-id and
sender/recipient email search modes, with sender-recipient as the
default.

#### Scenario: Default mode is sender-recipient

- GIVEN a user navigating to the elasticlogs page without parameters
- WHEN the page loads
- THEN the sender-recipient radio is selected
- AND the sender-recipient form fields are visible
- AND the message-id form fields are hidden

## NEW Requirements

### Requirement: Form Pre-Population via GET Parameters

The search form MUST read GET parameters from the URL and use them
to populate form fields and select the search mode.

#### Scenario: message_id parameter present

- GIVEN the URL contains a `message_id` GET parameter
- WHEN the page loads
- THEN the message-id field is populated with the parameter value
- AND the search mode is set to message-id
- AND a search is automatically submitted

#### Scenario: sender_recipient parameter present

- GIVEN the URL contains a `sender_recipient` GET parameter but no
  `message_id` parameter
- WHEN the page loads
- THEN the sender/recipient field is populated with the parameter value
- AND the search mode is set to sender-recipient
- AND a search is automatically submitted

#### Scenario: Both message_id and sender_recipient present

- GIVEN the URL contains both `message_id` and `sender_recipient`
  GET parameters
- WHEN the page loads
- THEN message-id mode takes priority
- AND the message-id field is populated
- AND a search is automatically submitted

#### Scenario: date_from and date_to parameters present

- GIVEN the URL contains `date_from` and/or `date_to` GET parameters
- WHEN the page loads
- THEN the corresponding date fields are populated with the parameter
  values, overriding the default 24-hour window

#### Scenario: No pre-population parameters

- GIVEN the URL contains no `message_id` or `sender_recipient`
  GET parameters
- WHEN the page loads
- THEN the default 24-hour time range is applied
- AND no automatic search is submitted
