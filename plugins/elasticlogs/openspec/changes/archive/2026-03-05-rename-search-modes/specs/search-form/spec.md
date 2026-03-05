# Delta for Search Form

## MODIFIED Requirements

### Requirement: Search Mode Selection

The search form MUST allow the user to switch between message-id and
sender/recipient email search modes.

#### Scenario: Mode selector uses new values

- GIVEN a logged-in user on the elasticlogs page
- WHEN the page loads
- THEN the radio buttons use values `message-id` and `sender-recipient`
- AND the labels use the localization keys `search_message_id` and
  `search_sender_recipient`

### Requirement: Message-ID Search Form Fields

The search form MUST use element ids and variable names that reflect
the message-id search mode.

#### Scenario: Message-ID fields container

- GIVEN the search mode is set to message-id
- WHEN the form renders
- THEN the fields container has id `elasticlogs-message-id-fields`

### Requirement: Sender/Recipient Search Form Fields

The search form MUST use element ids, variable names, and localization
keys that reflect the sender/recipient search mode.

#### Scenario: Sender/recipient fields container

- GIVEN the search mode is set to sender/recipient
- WHEN the form renders
- THEN the fields container has id `elasticlogs-sender-recipient-fields`
- AND the email input uses localization key `sender_recipient`
