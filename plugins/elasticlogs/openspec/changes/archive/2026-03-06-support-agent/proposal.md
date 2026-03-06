# Proposal: Support Agent Role

## Why

The plugin enforces a strict access control policy: users can only see
log entries for messages where they are the sender or a recipient. Support
staff who need to troubleshoot delivery issues for other users cannot
use the plugin to do so — they must resort to direct Elasticsearch access.

## What Changes

Introduce a "support agent" role. A configurable list of usernames
identifies support agents. When a support agent uses the search form,
an additional toggle lets them choose between searching their own logs
(normal access control) or searching all logs (bypassing access control).

Regular users are unaffected — they never see the toggle and access
control works as before.

## Scope

- New configuration key `support-agents`: an array of usernames
- PHP: detect if the logged-in user is a support agent
- UI: render a toggle (checkbox or similar) for support agents to
  opt into "search all" mode; hidden for regular users
- PHP: when a support agent searches in "all logs" mode, skip access
  control filtering in both `search_by_message_id()` and
  `search_by_sender_recipient()`
- Localization for the new UI element

## Non-goals

- Role-based access control beyond a flat list of usernames
- Admin panel for managing support agents
- Per-query audit logging of support agent searches
- Restricting which search modes support agents can use
