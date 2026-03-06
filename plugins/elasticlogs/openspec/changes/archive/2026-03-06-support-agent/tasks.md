## 1. Configuration

- [x] 1.1 Add `support-agents` key (default empty array) to `config.inc.php`

## 2. PHP — Support Agent Detection and Search Form

- [x] 2.1 Add `is_support_agent()` private method to `elasticlogs.php`
- [x] 2.2 In `render_searchform()`, conditionally render the "Search all logs" checkbox for support agents
- [x] 2.3 Pass support agent status to frontend via `set_env()`

## 3. JavaScript — AJAX Parameter

- [x] 3.1 Include `_search_all: 1` in search POST parameters when checkbox is checked

## 4. PHP — Access Control Bypass

- [x] 4.1 In `search_by_message_id()`, skip access control when support agent + search_all
- [x] 4.2 In `search_by_sender_recipient()`, skip access control filter when support agent + search_all

## 5. Localization

- [x] 5.1 Add `search_all` label to `en_US.inc` and `pt_PT.inc`
