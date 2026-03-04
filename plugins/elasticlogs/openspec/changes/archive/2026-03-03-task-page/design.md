## Context

The elasticlogs plugin currently has a minimal `init()` that loads config
and localization but registers no task, actions, or UI. Roundcube's plugin
API provides `register_task()` to add custom top-level pages, `add_button()`
to add taskbar entries, and `register_action()` to handle URL routes within
a task. The Elastic skin provides a standard layout structure with
`includes/layout.html`, `includes/menu.html`, and `includes/footer.html`.

Reference plugins in this codebase: `help` (simple task with templates)
and `xcalendar` (complex task with AJAX actions). The help plugin is the
closest analog for the pattern we need.

## Goals / Non-Goals

**Goals:**

- Register a Roundcube task at `?_task=elasticlogs` accessible from the taskbar
- Render a search page with a form supporting outbound and inbound modes
- Set up the AJAX plumbing so the form submits to a server-side action
- Provide a stub search action that returns empty results
- Establish the file structure (template, JS, CSS, localization) for
  future changes to build on

**Non-Goals:**

- Elasticsearch connectivity or query execution
- Actual log result rendering or export
- Pre-population of fields from mail/contact contexts
- Access control logic
- Loading indicators (no real latency yet with a stub)

## Decisions

### Decision: Register a dedicated Roundcube task

The plugin will call `$this->register_task('elasticlogs')` so that
`?_task=elasticlogs` is a first-class URL. This follows the pattern
used by `help` and `xcalendar`.

**Alternative considered**: Register actions under the `mail` task
(like the `nexus` plugin does with `plugin.nexus_upgrade`). Rejected
because the log search is a standalone activity, not subordinate to
any existing task.

### Decision: Taskbar button via add_button in startup hook

The taskbar button will be added in a `startup` hook callback (not
directly in `init()`), following the `help` plugin pattern. This ensures
the button is only added when the output is not framed and the user is
logged in.

### Decision: Single template with mode switching via JS

The page will use one Elastic skin template (`index.html`) containing
both the outbound and inbound form field sets. JavaScript will toggle
visibility of the relevant field set based on the selected search mode.

**Alternative considered**: Separate templates or server-side rendering
per mode. Rejected because both modes share the same page layout and
results area; client-side toggling is simpler and avoids page reloads.

### Decision: Search mode via radio buttons or tab-like toggle

The form will have a mode selector (outbound / inbound) at the top.
When switching modes, the irrelevant fields are hidden and the relevant
fields shown. This keeps the UI unified per the spec requirement.

### Decision: AJAX form submission

The search form will submit via Roundcube's `rcmail.http_post()` to a
registered action (`search`). The server-side handler will (for now)
return an empty result set via `rcmail_output_json`. This establishes
the async pattern for when real Elasticsearch queries are added later.

**Alternative considered**: Full page form POST with server-rendered
results. Rejected because AJAX is the standard Roundcube pattern for
dynamic content and will be needed for the loading states in future.

### Decision: Stub search action returns empty JSON

The `search` action handler will call `$rcmail->output->command()` to
send back an empty results payload. The JS will listen for this response
and update the results area. This avoids implementing any ES logic while
proving the end-to-end plumbing works.

### Decision: Template uses Elastic skin standard layout

The template will follow the Elastic skin conventions:
`includes/layout.html` + `includes/menu.html` at the top,
`includes/footer.html` at the bottom, with `#layout-content` as the
main content area. Custom content rendered via a registered template
handler (`plugin.searchform` and `plugin.searchresults`).

### Decision: File structure

```
plugins/elasticlogs/
├── elasticlogs.php
├── config.inc.php
├── composer.json
├── js/
│   └── elasticlogs.js
├── localization/
│   ├── en_US.inc
│   └── pt_PT.inc
└── skins/
    └── elastic/
        ├── elasticlogs.css
        └── templates/
            └── index.html
```

This follows the standard Roundcube plugin layout. The Elastic skin
template lives at `skins/elastic/templates/index.html` and is served
via `$rcmail->output->send('elasticlogs.index')`.

### Decision: Localization keys

All user-facing strings use Roundcube's `$this->add_texts('localization/')`
mechanism. Labels are auto-prefixed with `elasticlogs.` and available in
templates via `<roundcube:label name="elasticlogs.keyname" />` and in JS
via `rcmail.gettext('elasticlogs.keyname')`.

Initial keys needed:
- `task_title` — taskbar button and page title
- `search_outbound` — outbound mode label
- `search_inbound` — inbound mode label
- `message_id` — Message-ID field label
- `sender` — sender field label
- `date_from` — start date label
- `date_to` — end date label
- `search` — search button label
- `no_results` — empty results message

## Risks / Trade-offs

**[Risk] Task name collision** → The task name `elasticlogs` is
sufficiently unique to avoid collision with core Roundcube tasks or
common plugins. No mitigation needed.

**[Risk] Elastic skin hard dependency** → The template targets only the
Elastic skin. Users of other skins will fall back to Roundcube's generic
`plugin.html` template. Acceptable for v1.0 since the Elastic skin is
the standard skin for this deployment.

**[Trade-off] Stub search action** → The search button will work but
return no results. This is intentional — ES integration is scoped to a
separate change. The stub proves the plumbing and allows UI development
to proceed independently.
