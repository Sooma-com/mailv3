# Search Form Specification

## Purpose

Defines the search form UI behavior, including mode selection, form
fields, AJAX submission, results area, and localization.

## Requirements

### Requirement: Search Mode Selection

The search form MUST allow the user to switch between message-id and
sender/recipient email search modes.

#### Scenario: Mode selector is displayed

- GIVEN a logged-in user on the elasticlogs page
- WHEN the page loads
- THEN a mode selector with "Message-ID" and "Sender/recipient address" options is visible
- AND one mode is selected by default

#### Scenario: Switching modes toggles form fields

- GIVEN a user viewing the search form
- WHEN the user selects a different search mode
- THEN the form fields for the newly selected mode become visible
- AND the form fields for the previously selected mode are hidden

### Requirement: Message-ID Search Form Fields

The search form MUST display a Message-ID input field when in
message-id search mode.

#### Scenario: Message-ID form fields displayed

- GIVEN the search mode is set to message-id
- WHEN the form is visible
- THEN a text input labeled "Message-ID" is displayed
- AND a "Search" button is displayed

### Requirement: Sender/Recipient Search Form Fields

The search form MUST display a target email address input, start date,
and end date input fields when in sender/recipient search mode.

#### Scenario: Sender/recipient form fields displayed

- GIVEN the search mode is set to sender/recipient
- WHEN the form is visible
- THEN a text input labeled "Sender/Recipient" is displayed
- AND a datetime input labeled "From" (start date) is displayed
- AND a datetime input labeled "To" (end date) is displayed
- AND a "Search" button is displayed

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
search action.

#### Scenario: Message-ID form submission

- GIVEN the user has entered a Message-ID in message-id mode
- WHEN the user clicks the search button
- THEN an AJAX POST is sent to the search action
- AND the request includes the search mode and the Message-ID value

#### Scenario: Sender/recipient form submission

- GIVEN the user has filled in a target email address and time range
  in sender/recipient mode
- WHEN the user clicks the search button
- THEN an AJAX POST is sent to the search action
- AND the request includes the search mode, target email address,
  start date, and end date

#### Scenario: Message-ID search returns real results

- GIVEN the search action receives a message-id mode request
- WHEN the Message-ID matches entries in Elasticsearch
- AND the logged-in user is the sender or a recipient
- THEN real log entries are returned in the AJAX response
- AND the frontend renders them chronologically in the results area

#### Scenario: Search returns error

- GIVEN the search action receives a request
- WHEN Elasticsearch is unreachable or returns an error
- THEN a localized error message is displayed to the user

### Requirement: Results Area

The search page MUST include a results area below the search form.

#### Scenario: Empty results area on page load

- GIVEN a user who has just navigated to the elasticlogs page
- WHEN no search has been performed
- THEN the results area is visible but empty

#### Scenario: No-results message after search

- GIVEN a search that returns no results
- WHEN the AJAX response is received
- THEN the results area displays a localized "No results found" message

### Requirement: Localized Labels

All user-facing text in the search form and results area MUST use
Roundcube's localization system.

#### Scenario: Labels rendered in user's locale

- GIVEN a user with a configured locale
- WHEN the elasticlogs page is displayed
- THEN all form labels, button text, mode names, and messages are
  displayed in the user's language (where translations exist)
