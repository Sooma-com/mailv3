## 1. Dependencies and Configuration

- [x] 1.1 Run `composer require elastic/elasticsearch` in the plugin directory to add the ES PHP client
- [x] 1.2 Add localization keys for error messages (es_connect_error, es_query_error) in en_US.inc and pt_PT.inc

## 2. Elasticsearch Client

- [x] 2.1 Add a `build_es_client()` method that creates an Elasticsearch client from config (ClientBuilder, setHosts, setBasicAuthentication, setSSLVerification)
- [x] 2.2 Add a `hydrate_response()` helper that converts columnar ES|QL responses into associative arrays keyed by column name

## 3. Outbound Search Logic

- [x] 3.1 Update `action_search()` to read `_mode` from POST; when mode is `outbound`, delegate to `search_outbound()`
- [x] 3.2 Phase 1: ES|QL query filtering by `postfix.message-id`, sorted by @timestamp asc; sanitize input via `strtr()`
- [x] 3.3 Access control: scan phase 1 results for any entry where `postfix.from` matches `$_SESSION['username']`; if no match, return empty results
- [x] 3.4 Collect distinct `(host.hostname, postfix.queueid)` pairs from phase 1 results where both fields are non-null
- [x] 3.5 Phase 2: single ES|QL query combining message-id condition OR with all (hostname, queueid) pair conditions; replaces phase 1 results entirely
- [x] 3.6 Send hydrated result rows directly to frontend via `plugin.elasticlogs_search_response` command

## 4. Error Handling

- [x] 4.1 Wrap Elasticsearch calls in try/catch; on exception, log via `rcube::raise_error()` and send localized error message via `display_message` command

## 5. Frontend

- [x] 5.1 Update JS response handler to use `entry['@timestamp']` (ES|QL column name) instead of `entry.timestamp`
