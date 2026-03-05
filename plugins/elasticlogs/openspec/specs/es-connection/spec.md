# es-connection Specification

## Purpose

Defines how the plugin initializes and communicates with Elasticsearch,
including client construction, the ES|QL query interface, and error handling.
## Requirements
### Requirement: Elasticsearch Client Initialization

The plugin MUST initialize an Elasticsearch PHP client using the
configured host, credentials, and TLS settings.

#### Scenario: Client created with valid configuration

- GIVEN valid elasticsearch_host, elasticsearch_username,
  elasticsearch_password, and elasticsearch_index in the plugin config
- WHEN the search action needs to query Elasticsearch
- THEN a client is created using ClientBuilder with Basic Auth
- AND the configured host is used as the endpoint

#### Scenario: TLS verification disabled

- GIVEN elasticsearch_verify_tls is set to false
- WHEN the client is initialized
- THEN SSL certificate verification is disabled

#### Scenario: TLS verification enabled

- GIVEN elasticsearch_verify_tls is set to true or is not set
- WHEN the client is initialized
- THEN SSL certificate verification is enabled

### Requirement: ES|QL Query Interface

The plugin MUST use the ES|QL query interface (`$client->esql()->query()`)
for all Elasticsearch queries. A `hydrate_response()` helper converts
the columnar response (columns + values arrays) into an array of
associative arrays keyed by column name.

#### Scenario: ES|QL query executed

- GIVEN a valid ES|QL query string
- WHEN the query is sent via `$client->esql()->query()`
- THEN the columnar response is hydrated into rows with column names
  as keys (e.g. `@timestamp`, `message`, `postfix.from`)

### Requirement: Connection Error Handling

The plugin MUST handle Elasticsearch connection failures gracefully.

#### Scenario: Elasticsearch unreachable

- GIVEN the configured Elasticsearch host is unreachable
- WHEN a search query is attempted
- THEN a localized error message is displayed to the user
- AND no stack traces or credentials are exposed

#### Scenario: Authentication failure

- GIVEN invalid Elasticsearch credentials
- WHEN a search query is attempted
- THEN a localized error message is displayed to the user

