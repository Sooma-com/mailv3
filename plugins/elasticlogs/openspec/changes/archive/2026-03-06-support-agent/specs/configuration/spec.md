# Delta for Configuration

## ADDED Requirements

### Requirement: Support Agents Configuration

The system MUST allow configuration of a list of support agent
usernames in the plugin configuration.

#### Scenario: Support agents list configured

- GIVEN `$config['elasticlogs']['support-agents']` is set to an array
  of email addresses
- WHEN the plugin checks whether the logged-in user is a support agent
- THEN it compares the session username against the configured list
  using case-insensitive matching

#### Scenario: Support agents list not configured

- GIVEN `$config['elasticlogs']['support-agents']` is not set or is
  an empty array
- WHEN any user accesses the plugin
- THEN no user is treated as a support agent
- AND the plugin behaves identically to before this change
