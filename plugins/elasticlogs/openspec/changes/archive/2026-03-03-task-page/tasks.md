## 1. Task Registration and Routing

- [x] 1.1 Update `elasticlogs.php`: set `$task` property to match all tasks except login/logout, call `register_task('elasticlogs')`, guard on logged-in user
- [x] 1.2 Add `startup` hook that adds the taskbar button via `add_button()` to the `taskbar` container, includes JS and CSS
- [x] 1.3 Register `index` action that sets page title and sends the `elasticlogs.index` template
- [x] 1.4 Register `search` action (AJAX stub) that returns an empty results payload via `rcmail_output_json`

## 2. Template and Skin

- [x] 2.1 Create `skins/elastic/templates/index.html` with standard Elastic layout (layout.html, menu.html, footer.html), a `#layout-content` area, and placeholders for `plugin.searchform` and `plugin.searchresults` template objects
- [x] 2.2 Create `skins/elastic/elasticlogs.css` with styles for the search form layout, mode selector, form fields, and results area

## 3. Search Form (PHP handlers)

- [x] 3.1 Register template handlers for `plugin.searchform` and `plugin.searchresults` in the `index` action
- [x] 3.2 Implement `searchform` handler: render HTML with mode selector (outbound/inbound), outbound fields (Message-ID input), inbound fields (sender input, start/end datetime inputs), and search button
- [x] 3.3 Implement `searchresults` handler: render an empty container div for results, with a localized no-results message hidden by default

## 4. Client-Side JavaScript

- [x] 4.1 Create `js/elasticlogs.js`: on init, bind mode selector to toggle visibility of outbound/inbound field sets, set default time range (last 24h) on inbound datetime fields
- [x] 4.2 Bind search button: collect form values, call `rcmail.http_post()` to the `search` action with mode and field values
- [x] 4.3 Register AJAX response handler: on search response, update the results area (display no-results message for the stub)

## 5. Localization

- [x] 5.1 Create `localization/en_US.inc` with labels: task_title, search_outbound, search_inbound, message_id, sender, date_from, date_to, search, no_results
- [x] 5.2 Create `localization/pt_PT.inc` with Portuguese translations for all labels
- [x] 5.3 Update `init()` to call `add_texts('localization/', true)` so labels are available both server-side and client-side
