# Design: Support Agent Role

## Configuration

Add a `support-agents` key to the `$config['elasticlogs']` array in
`config.inc.php`. It holds a flat array of usernames (email addresses)
that are recognized as support agents. Default: empty array.

```php
$config['elasticlogs'] = [
    // ...existing keys...
    'support-agents' => ['support@example.com'],
];
```

## Support agent detection

In `elasticlogs.php`, add a private helper `is_support_agent()` that
checks whether `$_SESSION['username']` appears in the configured
`support-agents` array (case-insensitive comparison).

## Search form changes

In `render_searchform()`, if the logged-in user is a support agent,
render a checkbox labeled "Search all logs" (localized). The checkbox
has id `elasticlogs-search-all` and is hidden for non-support-agents
(not rendered at all — no hidden element in the DOM).

Pass the support agent status to the frontend via `rcmail->output->set_env()`
so that JavaScript knows whether to include the `_search_all` parameter
in AJAX requests.

## JavaScript changes

In `elasticlogs.js`, when building AJAX parameters for a search, check
the state of the `elasticlogs-search-all` checkbox (if it exists) and
include `_search_all: 1` in the POST parameters when checked.

## Backend search changes

In both `search_by_message_id()` and `search_by_sender_recipient()`:

1. Read the `_search_all` POST parameter.
2. If it is truthy AND `is_support_agent()` returns true, skip the
   access control checks that filter results by user email.
3. The double check (POST param + server-side role verification)
   prevents forged requests from regular users.

In `search_by_message_id()`: skip the `$access_granted` loop.
In `search_by_sender_recipient()`: skip the `array_filter()` call.

The Elasticsearch queries themselves remain unchanged — only the
post-query filtering is affected.

## Localization

Add labels for the new UI element:
- `search_all`: "Search all logs" / "Pesquisar todos os registos"
