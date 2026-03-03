# Configuration Specification

## Purpose

Defines the plugin configuration options, their format, defaults, and
validation behavior.

## Requirements

### Requirement: Configuration via Roundcube Config File

The system SHALL read all configuration from the plugin's `config.inc.php`
file, using Roundcube's standard `$this->load_config()` mechanism.

#### Scenario: Configuration loaded on init

- GIVEN a properly configured config.inc.php
- WHEN the plugin initializes
- THEN all settings are loaded from `$config['elasticlogs']`

### Requirement: Elasticsearch Endpoint Configuration

The system MUST allow configuration of the Elasticsearch endpoint URL.

#### Scenario: Endpoint specified

- GIVEN `$config['elasticlogs']['elasticsearch_host']` is set to a URL
- WHEN the plugin connects to Elasticsearch
- THEN it uses the configured URL as the endpoint

### Requirement: Elasticsearch Credentials Configuration

The system MUST allow configuration of HTTP Basic Auth credentials
for Elasticsearch.

#### Scenario: Credentials specified

- GIVEN `$config['elasticlogs']['elasticsearch_username']` and
  `$config['elasticlogs']['elasticsearch_password']` are set
- WHEN the plugin connects to Elasticsearch
- THEN it authenticates using the configured username and password

### Requirement: Index Name Configuration

The system MUST allow configuration of the Elasticsearch index to query.

#### Scenario: Index name specified

- GIVEN `$config['elasticlogs']['elasticsearch_index']` is set
- WHEN the plugin executes a search query
- THEN it targets the configured index

### Requirement: TLS Verification Configuration

The system SHOULD allow disabling TLS certificate verification for
Elasticsearch connections.

#### Scenario: TLS verification disabled

- GIVEN `$config['elasticlogs']['elasticsearch_verify_tls']` is set to false
- WHEN the plugin connects to an HTTPS Elasticsearch endpoint
- THEN certificate verification is skipped

#### Scenario: TLS verification enabled by default

- GIVEN `$config['elasticlogs']['elasticsearch_verify_tls']` is not set
- WHEN the plugin connects to an HTTPS Elasticsearch endpoint
- THEN certificate verification is performed (secure default)

### Requirement: Shared Credentials

The system SHALL use a single set of Elasticsearch credentials for all
users. Per-user Elasticsearch authentication is not supported.

#### Scenario: All users share the same ES connection

- GIVEN any logged-in user performing a log search
- WHEN the plugin queries Elasticsearch
- THEN it uses the globally configured endpoint and credentials
- AND access control is enforced at the plugin level, not at Elasticsearch
