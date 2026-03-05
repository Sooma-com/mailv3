# UI Specification

## Purpose

Defines the user interface for the Elasticlogs plugin, including the
dedicated task page, search forms, results display, and export functionality.

## Requirements

### Requirement: Dedicated Task Page

The system SHALL register a dedicated Roundcube task that provides the
log search interface.

#### Scenario: Task appears in navigation

- GIVEN a logged-in Roundcube user
- WHEN the user views the task menu
- THEN an "Elasticlogs" entry (localized) is available
- AND clicking it navigates to the log search page

### Requirement: Unified Search Interface

The system SHALL provide a single page where users can perform both
types of searches. Either by message-id or by sender/recipient address

#### Scenario: Search mode selection

- GIVEN a user on the Elasticlogs page
- WHEN the page loads
- THEN the user can choose between searching by Message-ID or by sender/recipient
  email address modes

### Requirement: Message-ID Search Form

The system SHALL provide a form for outbound message log search
containing a Message-ID input field.

#### Scenario: Message-ID search form displayed

- GIVEN the user selects by message-id search mode
- WHEN the form is displayed
- THEN it contains a text input for Message-ID
- AND a submit button to execute the search

#### Scenario: Pre-populated Message-ID

- GIVEN the user navigates to the Elasticlogs page from a mail context
  (e.g., a context menu on a sent message)
- WHEN the page loads
- THEN the Message-ID field is pre-populated with the message's ID
- AND the search mode is set to search by message-id

### Requirement: Sender/Recipient Search Form

The system SHALL provide a form for message log search by sender/recipient containing
target email address and time range inputs.

#### Scenario: Sender/recipient search form displayed

- GIVEN the user selects sender/recipient search mode
- WHEN the form is displayed
- THEN it contains a text input for target email address
- AND date/time inputs for the time range (start and end)
- AND a submit button to execute the search

#### Scenario: Default time range

- GIVEN the user opens the inbound search form
- WHEN no custom time range has been specified
- THEN the end time defaults to now
- AND the start time defaults to 24 hours before now

#### Scenario: Pre-populated sender from contact context

- GIVEN the user navigates to the Elasticlogs page from a contact context
  (e.g., a context menu on an address book entry)
- WHEN the page loads
- THEN the target email field is pre-populated with the contact's email address
- AND the search mode is set to inbound

### Requirement: Results Display

The system SHALL display search results as a chronological list of log entries.

#### Scenario: Results shown after successful search

- GIVEN a search that returns log entries
- WHEN results are displayed
- THEN each entry shows its timestamp and the raw log message
- AND entries are ordered chronologically (oldest first)

#### Scenario: Empty results

- GIVEN a search that returns no log entries
- WHEN the results area updates
- THEN a localized message indicates no logs were found

### Requirement: Results Area Extensibility

The system SHOULD structure the results display area such that future
enhancements (e.g., human-readable event summaries, highlighted key events)
can be added without restructuring the UI.

#### Scenario: Structured result container

- GIVEN the results display area
- WHEN log entries are rendered
- THEN each entry is rendered as a distinct element that can be individually
  enhanced or annotated in the future

### Requirement: Text Export

The system SHALL provide a button to download the current search results
as a plain text file.

#### Scenario: Download button available

- GIVEN search results are displayed
- WHEN the user clicks the download button
- THEN a .txt file is generated with one raw log line per entry
- AND the browser initiates a file download

#### Scenario: Download unavailable when no results

- GIVEN no search results are displayed (empty or no search performed)
- WHEN the user views the page
- THEN the download button is disabled

### Requirement: Localization

The system MUST use Roundcube's localization facilities for all user-facing
strings in the UI.

#### Scenario: Localized labels

- GIVEN a user with a specific locale configured in Roundcube
- WHEN the Elasticlogs page is displayed
- THEN all labels, buttons, messages, and error texts are displayed
  in the user's configured language (where translations are available)

### Requirement: Loading State

The system SHOULD indicate when a search is in progress.

#### Scenario: Search in progress

- GIVEN a user who has submitted a search
- WHEN the query is being processed
- THEN a loading indicator is displayed
- AND the submit button is disabled to prevent duplicate submissions
