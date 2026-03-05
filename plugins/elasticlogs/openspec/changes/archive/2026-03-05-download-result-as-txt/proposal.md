## Why

Users can view log results in the browser but have no way to save them
for offline analysis or sharing. A download button lets them export the
current result set as a plain text file without an additional server
request, since all the data is already present in the frontend.

## What Changes

- Add a download button to the results area that is only visible when
  results are present
- In JavaScript, generate a TXT file from the displayed results (one
  log line per entry) and trigger a browser download via a Blob URL
- Hide the button when there are no results or when a new search
  clears the previous results
- Add a localization key for the download button label

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `search-form`: The results area gains a download button that appears
  when results are non-empty

## Impact

- **Modified files**: `elasticlogs.php` (add button element in
  `render_searchresults()`), `js/elasticlogs.js` (download logic and
  button visibility), `localization/en_US.inc` and `pt_PT.inc`
  (download button label)
- **No new dependencies**
- **No backend changes** — entirely client-side

## Non-goals

- Server-side file generation
- Alternative export formats (CSV, JSON)
- Customizable file name beyond a sensible default
