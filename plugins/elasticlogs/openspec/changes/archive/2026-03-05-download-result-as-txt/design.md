## Context

The results area currently renders log entries as `<div>` elements with
`entry['@timestamp'] + ' ' + entry.message` as text content. The
response data is available in the JS event handler. This change adds a
download button that builds a TXT file from the same data.

## Goals / Non-Goals

**Goals:**

- Add a download button visible only when results are non-empty
- Generate the TXT file entirely in JavaScript using a Blob
- Trigger a browser download with a sensible default filename

**Non-Goals:**

- Server-side file generation
- Alternative formats
- Loading/progress indication for the download

## Decisions

### Decision: Button rendered in PHP, visibility toggled in JS

The download button HTML is rendered by `render_searchresults()` in PHP,
initially hidden (`style="display:none"`). The JS response handler shows
or hides it based on whether results are present.

### Decision: Generate file via Blob URL

The JS click handler builds a text string by joining each entry's
`@timestamp + ' ' + message` with newlines, creates a `Blob` with
`text/plain` MIME type, creates an object URL, and triggers download
via a temporary `<a>` element with `download` attribute. The object
URL is revoked after the click.

### Decision: Filename includes a timestamp

The download filename will be `elasticlogs-{ISO date}.txt` so that
multiple downloads are distinguishable.

### Decision: Store response data for download

The response data array is stored in a variable scoped to the rcmail
init handler, updated on each search response. The download handler
reads from this variable rather than scraping the DOM.

## Risks / Trade-offs

**[Trade-off] Large result sets in memory** — The full result set is
held in a JS variable. This is already the case for rendering, so no
additional memory cost.

## Migration Plan

- No configuration or backend changes needed
