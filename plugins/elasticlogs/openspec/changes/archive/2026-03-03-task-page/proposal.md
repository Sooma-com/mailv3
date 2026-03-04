## Why

This is the foundational change for the elasticlogs plugin. Almost every
user interaction will revolve around a search form that gathers filtering
criteria, queries Elasticsearch for log entries, and presents the results.
Before any search or display logic can be built, the plugin needs a
dedicated task page registered with Roundcube. This change creates that
page, adds the search form UI, and sets up the empty results area — the
skeleton on which all subsequent features will be built.

## What Changes

- Register "elasticlogs" as a Roundcube task so that `?_task=elasticlogs`
  routes to the plugin
- Create the task page template with the Elastic skin layout
- Implement a unified search form with two modes:
  - **Outbound**: a Message-ID text input
  - **Inbound**: a sender email input and start/end datetime inputs
    (defaulting to the last 24 hours)
- Add an empty results area below the form, structured for future
  extensibility (log display, export, event summaries)
- Add client-side JS to handle search mode switching and form submission
  (AJAX action registration, no backend search logic yet)
- Register a server-side action endpoint for search requests (stub that
  returns empty results)
- Add localization files (en_US, pt_PT) for all UI labels
- Add skin-specific CSS for the search form and results layout

## Capabilities

### New Capabilities

- `task-registration`: Roundcube task registration, taskbar button, routing
  of `?_task=elasticlogs` to the plugin's index action
- `search-form`: Unified search form with outbound/inbound mode switching,
  form fields, default time range, and AJAX submission to a stub endpoint

### Modified Capabilities

_(none — this is the first implementation change; existing specs describe
target behavior but no prior implementation exists to modify)_

## Impact

- **New files**: task page template, JS, CSS, localization files
- **Modified files**: `elasticlogs.php` (task registration, action handlers,
  button, template handler registration)
- **Dependencies**: none beyond what is already in composer.json
- **No Elasticsearch queries yet** — the search action will be a stub
  returning empty results; ES integration is a subsequent change

## Non-goals

- Elasticsearch connectivity and query execution
- Actual log result display and formatting
- Text export / download functionality
- Pre-population of form fields from mail or contact contexts
- Access control enforcement (no search results yet to filter)
- Loading state indicators (no real async operation yet)
