# Delta for Search Form

## MODIFIED Requirements

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
