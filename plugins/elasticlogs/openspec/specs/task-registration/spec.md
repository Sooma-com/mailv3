# Task Registration Specification

## Purpose

Defines how the elasticlogs plugin registers itself as a Roundcube task,
adds a taskbar button, and routes requests to action handlers.

## Requirements

### Requirement: Roundcube Task Registration

The plugin MUST register "elasticlogs" as a Roundcube task so that the
URL `?_task=elasticlogs` is routed to the plugin.

#### Scenario: Task is registered on plugin init

- GIVEN the elasticlogs plugin is active
- WHEN Roundcube initializes plugins
- THEN "elasticlogs" is added to the list of valid Roundcube tasks
- AND navigating to `?_task=elasticlogs` renders the plugin's page

#### Scenario: Task is not registered for unauthenticated users

- GIVEN a user who is not logged in
- WHEN Roundcube initializes plugins
- THEN the elasticlogs task is not registered

### Requirement: Taskbar Button

The plugin MUST add a button to the Roundcube taskbar that navigates to
the elasticlogs task.

#### Scenario: Button appears in taskbar

- GIVEN a logged-in Roundcube user
- WHEN the page renders (any task)
- THEN a localized "Delivery Logs" button is visible in the taskbar

#### Scenario: Button navigates to elasticlogs task

- GIVEN a logged-in user viewing any Roundcube page
- WHEN the user clicks the elasticlogs taskbar button
- THEN the browser navigates to `?_task=elasticlogs`

### Requirement: Index Action

The plugin MUST register an `index` action that serves the main page
template when the elasticlogs task is accessed.

#### Scenario: Default action serves the page

- GIVEN a logged-in user navigating to `?_task=elasticlogs`
- WHEN no specific action is requested
- THEN the index action renders the search page template
- AND the page title is set to the localized task title

### Requirement: Search Action Endpoint

The plugin MUST register a `search` action that accepts AJAX requests
from the search form.

#### Scenario: Search action responds to AJAX POST

- GIVEN a logged-in user on the elasticlogs page
- WHEN the search form is submitted
- THEN the request is sent as an AJAX POST to the `search` action
- AND the server responds with a JSON payload

#### Scenario: Stub search returns empty results

- GIVEN the search action receives a request
- WHEN no Elasticsearch integration is configured
- THEN the action returns an empty results payload
