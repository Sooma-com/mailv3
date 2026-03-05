## 1. PHP — Default Mode

- [x] 1.1 Change default checked radio from message-id to sender-recipient
- [x] 1.2 Swap initial visibility: message-id fields hidden, sender-recipient fields visible

## 2. JavaScript — GET Parameter Handling

- [x] 2.1 Read `message_id`, `sender_recipient`, `date_from`, `date_to` from URL via URLSearchParams
- [x] 2.2 If `message_id` is present: populate field, select message-id mode, trigger radio change event
- [x] 2.3 If `sender_recipient` is present (and no `message_id`): populate field, select sender-recipient mode
- [x] 2.4 If `date_from`/`date_to` are present: populate date fields (overriding 24h default)
- [x] 2.5 If either `message_id` or `sender_recipient` was set: auto-submit by clicking search button
