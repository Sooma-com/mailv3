## Context

The elasticlogs plugin has a registered task page with a search form that
submits via AJAX to a stub `search` action. This change replaces the stub
with a real Elasticsearch integration for outbound (by Message-ID) search.

The Elasticsearch cluster runs v9.x, accessible via HTTPS with Basic Auth.
The official PHP client (`elastic/elasticsearch-php` v9.x) will be used.
The index to query is configured in `config.inc.php` and is already
populated with connection settings.

## Goals / Non-Goals

**Goals:**

- Initialize the ES PHP client from plugin configuration
- Implement the two-phase outbound query (Message-ID → queue-id expansion)
- Enforce access control: verify the logged-in user is the sender
- Return chronologically sorted log entries to the frontend
- Render real log entries in the results area
- Handle connection and query errors gracefully

**Non-Goals:**

- Inbound search implementation
- Text export / download
- rspamd.message-id dedicated querying in phase 1 (rspamd entries
  sharing a queue-id are naturally included in phase 2)
- Loading state indicators

## Decisions

### Decision: Use elastic/elasticsearch-php v9.x via ClientBuilder

The official PHP client provides `ClientBuilder` with `setHosts()`,
`setBasicAuthentication()`, and `setSSLVerification()`. This maps
directly to our configuration keys.

```php
$client = ClientBuilder::create()
    ->setHosts([$config['elasticsearch_host']])
    ->setBasicAuthentication($config['elasticsearch_username'], $config['elasticsearch_password'])
    ->setSSLVerification($config['elasticsearch_verify_tls'])
    ->build();
```

The client instance will be created on demand in `action_search()`,
not during `init()`, to avoid unnecessary connections on every page load.

### Decision: Use Elasticsearch Search API with bool queries

Phase 1 query: `bool.must` with a `term` match on `postfix.message-id`.

Phase 2 query: `bool.should` with one clause per `(host.hostname,
postfix.queueid)` pair, each as a `bool.must` with two `term` matches.
`minimum_should_match: 1`.

Both queries use `_source` to request only the fields we need, and
`sort` by `@timestamp: asc`.

**Alternative considered**: ES|QL query language (as used in the curl
examples during exploration). Rejected because the PHP client's
`search()` method with JSON DSL is the standard approach, better
documented, and more composable for building dynamic queries.

### Decision: Access control via postfix.from check

After phase 1 returns results, we check if any entry has a
`postfix.from` value matching `$_SESSION['username']`. If none match,
we return an empty result set immediately without proceeding to phase 2.

This is sufficient for outbound search because the user is searching
by a Message-ID they claim to have sent. If they are not the sender
(`postfix.from`), they should not see the logs.

### Decision: Deduplicate by _id before returning results

Phase 1 and phase 2 may return overlapping documents (entries that
match both the Message-ID and a queue-id pair). We deduplicate by
Elasticsearch document `_id` before sorting and returning.

### Decision: Return timestamp and raw message to frontend

Each result entry sent to the JS frontend will contain `timestamp`
(the `@timestamp` value) and `message` (the raw `message` field).
The existing JS response handler already renders these two fields.

### Decision: Error handling with localized user messages

ES connection or query failures are caught and result in a
`display_message` command with a localized error string. No stack
traces or credentials are exposed.

### Decision: Size limit on queries

Both phase 1 and phase 2 queries will use `size: 1000` to avoid
unbounded result sets. This is a reasonable upper bound for a single
message's log trail.

## Risks / Trade-offs

**[Risk] Elasticsearch unreachable** → Caught by try/catch around
the client calls. A localized error message is displayed. The plugin
continues to function for other tasks.

**[Risk] Large result sets** → The `size: 1000` limit caps both
phases. A single message is unlikely to generate more than a few
hundred log entries across all servers.

**[Trade-off] No rspamd.message-id in phase 1** → We only query
`postfix.message-id` in phase 1. Rspamd entries that share a
queue-id with a postfix entry will be picked up in phase 2. Rspamd
entries without a queue-id association will be missed. This is
acceptable for v1.0 and can be added later without changing the
architecture.

**[Trade-off] Access control checks only postfix.from** → For outbound
search, checking only the sender is correct. Inbound search (future
change) will need a different access control check.

## Migration Plan

- Run `composer require elastic/elasticsearch` in the plugin directory
  to add the dependency
- The config.inc.php already contains connection settings
- No database migrations or data changes required
- Rollback: revert to the stub `action_search()` if issues arise
