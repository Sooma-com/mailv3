## 1. Dependencies and Configuration

- [ ] 1.1 Run `composer require elastic/elasticsearch` in the plugin directory to add the ES PHP client
- [ ] 1.2 Add localization keys for error messages (es_connect_error, es_query_error) in en_US.inc and pt_PT.inc

## 2. Elasticsearch Client

- [ ] 2.1 Add a method to `elasticlogs.php` that builds and returns an Elasticsearch client from config (ClientBuilder, setHosts, setBasicAuthentication, setSSLVerification)

## 3. Outbound Search Logic

- [ ] 3.1 Update `action_search()` to read `_mode` from POST; when mode is `outbound`, read `_message_id` and execute phase 1 query (term match on `postfix.message-id`, size 1000, sorted by @timestamp asc)
- [ ] 3.2 After phase 1, check access control: scan results for any entry where `postfix.from` matches `$_SESSION['username']`; if no match, return empty results
- [ ] 3.3 Collect distinct `(host.hostname, postfix.queueid)` pairs from phase 1 results where both fields are non-null
- [ ] 3.4 Execute phase 2 query: bool/should with one must clause per pair, size 1000, sorted by @timestamp asc
- [ ] 3.5 Merge phase 1 and phase 2 results, deduplicate by `_id`, sort by @timestamp ascending
- [ ] 3.6 Map results to `[{timestamp, message}]` array and send via `plugin.elasticlogs_search_response` command

## 4. Error Handling

- [ ] 4.1 Wrap Elasticsearch calls in try/catch; on exception, send a localized error message via `$rcmail->output->command('display_message', ...)` and return empty results

## 5. Frontend

- [ ] 5.1 Verify the existing JS response handler correctly renders real log entries (no changes expected; confirm the `entry.timestamp + ' ' + entry.message` rendering works with the response format)
