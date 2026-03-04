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

### Decision: Use ES|QL as the query language

Queries use the ES|QL query language via `$client->esql()->query()`,
rather than JSON DSL via `$client->search()`. ES|QL provides a more
readable pipe-based syntax and returns a columnar response (columns +
values arrays).

Phase 1 query:

```esql
FROM {index}
| WHERE `postfix.message-id` == "{message_id}"
| SORT @timestamp ASC
```

Phase 2 query combines the message-id condition with all discovered
(hostname, queueid) pairs in a single OR expression, replacing
the phase 1 result set entirely:

```esql
FROM {index}
| WHERE (`postfix.message-id` == "{message_id}")
    OR (postfix.queueid == "{qid1}" AND host.hostname == "{host1}")
    OR (postfix.queueid == "{qid2}" AND host.hostname == "{host2}")
    ...
| SORT @timestamp ASC
```

A `hydrate_response()` helper converts the columnar ES|QL response
into an array of associative arrays keyed by column name (e.g.
`@timestamp`, `message`, `postfix.from`, `host.hostname`).

User input is sanitized by stripping backslashes and double quotes
via `strtr()` before interpolation into ES|QL strings.

### Decision: Access control via postfix.from check

After phase 1 returns results, we check if any entry has a
`postfix.from` value matching `$_SESSION['username']`. If none match,
we return an empty result set immediately without proceeding to phase 2.

This is sufficient for outbound search because the user is searching
by a Message-ID they claim to have sent. If they are not the sender
(`postfix.from`), they should not see the logs.

### Decision: Phase 2 replaces phase 1 results (no dedup needed)

Because ES|QL does not return document `_id` fields, we cannot
deduplicate by document ID as would be done with JSON DSL. Instead,
phase 2 includes the message-id condition in its WHERE clause
alongside the queue-id pair conditions, making its result set a
superset of phase 1. The phase 1 result set is discarded when
phase 2 executes.

### Decision: Return full ES|QL rows to frontend

Each result row sent to the JS frontend is the hydrated ES|QL row,
containing all returned columns with their ES field names (e.g.
`@timestamp`, `message`, `postfix.from`, `host.hostname`). The JS
response handler reads `entry['@timestamp']` and `entry.message`.

### Decision: Error handling with localized user messages

ES connection or query failures are caught and result in a
`display_message` command with a localized error string. No stack
traces or credentials are exposed.

## Risks / Trade-offs

**[Risk] Elasticsearch unreachable** → Caught by try/catch around
the client calls. A localized error message is displayed. The plugin
continues to function for other tasks.

**[Risk] Large result sets** → ES|QL returns all matching rows by
default. A single message is unlikely to generate more than a few
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

**[Trade-off] ES|QL string interpolation** → User input is sanitized
by stripping backslashes and double quotes, but ES|QL does not
support parameterized queries. This is acceptable because the
Message-ID field is controlled input from the webmail system, and
the sanitization prevents injection via the form.

## Migration Plan

- Run `composer require elastic/elasticsearch` in the plugin directory
  to add the dependency
- The config.inc.php already contains connection settings
- No database migrations or data changes required
- Rollback: revert to the stub `action_search()` if issues arise
