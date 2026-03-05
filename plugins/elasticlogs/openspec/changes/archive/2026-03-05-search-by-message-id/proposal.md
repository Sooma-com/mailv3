## Why

The task page currently has a stub search endpoint that returns empty
results. This change connects the outbound search form to Elasticsearch,
implementing the first real search capability. Users will be able to
enter a Message-ID and retrieve all delivery log entries associated
with that message, traced across multiple mail servers.

## What Changes

- Add the `elastic/elasticsearch-php` dependency via composer
- Populate `config.inc.php` with Elasticsearch connection settings
  (host, credentials, index, TLS verification toggle)
- Implement Elasticsearch client initialization using configured
  credentials (Basic Auth, optional TLS verification skip)
- Replace the stub `search` action with real logic for outbound mode,
  using ES|QL as the query language:
  1. Phase 1: ES|QL query filtering by `postfix.message-id`
  2. Access control: check if any returned entry has a `postfix.from`
     value matching the logged-in user's email. If not, return an
     empty result set.
  3. Phase 2: Collect all distinct `(host.hostname, postfix.queueid)`
     pairs from phase 1 results, query for all log entries matching
     the message-id OR any of those pairs in a single ES|QL query
  4. Sort by `@timestamp` ascending (via ES|QL SORT), return to
     the frontend
- Update the frontend JS to render returned log entries using ES|QL
  column names (`@timestamp` + `message`) in the results area
- Add localized error messages for connection failures

## Capabilities

### New Capabilities

- `es-connection`: Elasticsearch client initialization, Basic Auth,
  TLS configuration, error handling for connection failures
- `outbound-search`: Two-phase outbound query strategy (Message-ID
  lookup, then queue-id expansion), access control by sender match,
  result merging and chronological sorting

### Modified Capabilities

- `configuration`: Adding concrete Elasticsearch configuration keys
  to `config.inc.php`
- `search-form`: The search action for outbound mode now performs
  a real query instead of returning a stub response

## Impact

- **New dependency**: `elastic/elasticsearch-php` added to composer.json
- **Modified files**: `elasticlogs.php` (search action, ES client),
  `config.inc.php` (ES connection settings), `js/elasticlogs.js`
  (result rendering), localization files (error messages)
- **Infrastructure**: Requires network access from the webmail server
  to the Elasticsearch endpoint

## Non-goals

- Inbound search (by sender + time range) — separate change
- Text export / download of results
- Pre-population of Message-ID from mail context
- rspamd log correlation (rspamd entries that share a queue-id will
  naturally be included in phase 2; dedicated rspamd.message-id
  querying is deferred)
- Loading state indicators
