# Delta for Configuration

## MODIFIED Requirements

### Requirement: Configuration via Roundcube Config File

The system SHALL read all configuration from the plugin's `config.inc.php`
file, using Roundcube's standard `$this->load_config()` mechanism.

#### Scenario: Configuration loaded on init

- GIVEN a properly configured config.inc.php
- WHEN the plugin initializes
- THEN all settings are loaded from `$config['elasticlogs']`

#### Scenario: Elasticsearch settings present in config

- GIVEN `$config['elasticlogs']` contains elasticsearch_host,
  elasticsearch_username, elasticsearch_password, elasticsearch_index,
  and optionally elasticsearch_verify_tls
- WHEN the plugin reads its configuration
- THEN all Elasticsearch connection parameters are available for
  client initialization
