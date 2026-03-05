# Search Form Specification

## Purpose

Defines the search form UI behavior, including mode selection, form
fields, AJAX submission, results area, and localization.
## Requirements
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

### Requirement: Default Time Range for Sender/Recipient Search

The sender/recipient search form MUST default the time range to the
last 24 hours.

#### Scenario: Default time range on page load

- GIVEN the search mode is set to sender/recipient
- WHEN the form first loads
- THEN the end date defaults to the current date and time
- AND the start date defaults to 24 hours before the current date and time

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

### Requirement: Results Area

The search page MUST include a results area below the search form,
with a download button for exporting results.

#### Scenario: Download button visible when results present

- GIVEN a search that returned results
- WHEN the results area displays log entries
- THEN a localized download button is visible

#### Scenario: Download button hidden when no results

- GIVEN no results are displayed (empty, no search, or cleared)
- WHEN the user views the results area
- THEN the download button is hidden

#### Scenario: Download generates TXT file

- GIVEN results are displayed and the download button is visible
- WHEN the user clicks the download button
- THEN a .txt file is generated in the browser containing one line
  per log entry (timestamp + space + raw message)
- AND the browser initiates a file download
- AND the filename includes a timestamp for uniqueness

### Requirement: Localized Labels

All user-facing text in the search form and results area MUST use
Roundcube's localization system.

#### Scenario: Labels rendered in user's locale

- GIVEN a user with a configured locale
- WHEN the elasticlogs page is displayed
- THEN all form labels, button text, mode names, and messages are
  displayed in the user's language (where translations exist)

