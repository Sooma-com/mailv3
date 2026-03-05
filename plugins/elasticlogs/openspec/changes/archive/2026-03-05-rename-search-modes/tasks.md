## 1. Localization

- [x] 1.1 Rename `search_outbound` to `search_message_id` and update text in en_US.inc and pt_PT.inc
- [x] 1.2 Rename `search_inbound` to `search_sender_recipient` and update text in en_US.inc and pt_PT.inc
- [x] 1.3 Rename `sender` to `sender_recipient` and update text in en_US.inc and pt_PT.inc

## 2. PHP — Search Form

- [x] 2.1 In `render_searchform()`: change radio values from `outbound`/`inbound` to `message-id`/`sender-recipient`
- [x] 2.2 In `render_searchform()`: update localization key references (`search_outbound` → `search_message_id`, `search_inbound` → `search_sender_recipient`, `sender` → `sender_recipient`)
- [x] 2.3 In `render_searchform()`: rename HTML ids from `elasticlogs-outbound-fields`/`elasticlogs-inbound-fields` to `elasticlogs-message-id-fields`/`elasticlogs-sender-recipient-fields`
- [x] 2.4 In `render_searchform()`: rename PHP variable names from `$mode_outbound`/`$mode_inbound`/`$outbound_fields`/`$inbound_fields` to `$mode_message_id`/`$mode_sender_recipient`/`$message_id_fields`/`$sender_recipient_fields`

## 3. PHP — Search Action

- [x] 3.1 In `action_search()`: change mode check from `'outbound'` to `'message-id'`
- [x] 3.2 Rename method `search_outbound()` to `search_by_message_id()`
- [x] 3.3 In `search_by_message_id()`: update access control to also check `postfix.kv.to` against the logged-in user

## 4. JavaScript

- [x] 4.1 Update mode-switching logic: change `'outbound'` to `'message-id'` and element id references from `elasticlogs-outbound-fields`/`elasticlogs-inbound-fields` to `elasticlogs-message-id-fields`/`elasticlogs-sender-recipient-fields`
- [x] 4.2 Update AJAX parameter building: change `'outbound'` check to `'message-id'`, rename `_sender` parameter id reference from `elasticlogs-sender` to `elasticlogs-sender-recipient`
