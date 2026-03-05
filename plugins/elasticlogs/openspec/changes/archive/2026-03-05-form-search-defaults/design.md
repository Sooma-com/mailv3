## Context

The elasticlogs search form currently defaults to message-id mode with
no way to pre-populate fields from an external link. Future context menu
integrations will link to `?_task=elasticlogs&message_id=...` or
`?_task=elasticlogs&sender_recipient=...`. This change adds the
plumbing to read those URL parameters and act on them.

## Goals / Non-Goals

**Goals:**

- Pre-populate form fields from URL GET parameters
- Select the correct search mode based on which parameters are present
- Auto-submit a search when pre-populated
- Change default mode to sender-recipient

**Non-Goals:**

- Context menu integrations (separate changes)
- Changing the search AJAX protocol

## Decisions

### Decision: Read GET parameters via URLSearchParams

On init, the JS reads `message_id`, `sender_recipient`, `date_from`,
and `date_to` from `window.location.search` using `URLSearchParams`.
This is supported in all modern browsers and by Roundcube's target
browser matrix.

### Decision: Mode selection priority

1. If `message_id` is present → message-id mode
2. Else if `sender_recipient` is present → sender-recipient mode
3. Else → sender-recipient mode (default)

When a mode is selected programmatically, the corresponding radio
button is checked and a `change` event is dispatched to trigger
the existing field-visibility toggle logic.

### Decision: Auto-submit via search button click

If any pre-population parameter (`message_id` or `sender_recipient`)
is present, the search button's click handler is invoked
programmatically after field population. This reuses the existing
submission logic without duplication.

### Decision: Default mode changes to sender-recipient

The PHP form renders with sender-recipient radio checked and its
fields visible by default. The message-id fields are hidden. This
is the more common entry point when navigating directly to the
page without parameters.

### Decision: date_from and date_to override 24h default

If GET parameters provide date values, they replace the default
24-hour window. If not provided, the existing 24-hour default
remains.

## Risks / Trade-offs

**[Risk] URL parameters visible in browser history** — Message-IDs
and email addresses will appear in the URL. This is acceptable since
the data is not sensitive (users already see it in their mail client)
and matches standard webmail URL patterns.

## Migration Plan

- No configuration or backend changes needed
- The default mode change is cosmetic and non-breaking
