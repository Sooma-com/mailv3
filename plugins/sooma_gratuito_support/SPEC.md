# sooma_gratuito_support: specification

A Roundcube plugin that replaces the Horde `support` application
(`Gratuito/webapp/install/support`). It does two jobs:

1. **Support console:** support staff look up a free-mail account in the LDAP
   directory, see its state, and fix common problems (reactivate, undelete,
   recovery contacts, password reset).
2. **Recovery contacts in Settings:** end users set their own password-recovery
   email and mobile phone.

This Roundcube install serves two services: *profissional* and *gratuito*
(a historical internal name; the service is no longer free). The plugin is
for gratuito only, as its name says. Enable it on exactly these hosts:
`correio.aeiou.pt`, `correio.portugalmail.pt` and `webmail.clix.pt`. It must
never be enabled for profissional, which uses the DB directory instead of
LDAP. The support console and the Settings section are both available on all
three gratuito hosts.

---

## 1. What the old application did

### 1.1 Support console (`index.php`, `search.php`, `update.php`)

Access: the logged-in user must appear in `$conf['support']['administrators']`,
a map of `domain => [admin logins]`. Viewing an account also requires the
admin to be listed for **that account's domain**.

**Search** (by email address):

- If the address is a `JammMailAlias`, follow its `maildrop` to the real account.
- Load the `JammMailAccount` entry, reading these attributes: `mail`, `quota`,
  `secretQuestion`, `secretAnswer` (legacy, see below), `creationTime`, `accountActive`, `delete`,
  `regIp`, `recoveryPhone`, `recoveryEmail`, `spammer`.
- List the account's aliases (`JammMailAlias` entries whose `maildrop` is the account).
- For active accounts, read IMAP usage with `GETQUOTAROOT INBOX` while logged in
  as the Dovecot master user (`<mail>*<master_user>`).

**Account page** shows and acts on the following:

| Field | Display | Action |
|---|---|---|
| Address | `mail` | none |
| Creation | `creationTime` (unix epoch, shown in Europe/Lisbon) and `regIp` | none |
| Active | `accountActive` (FALSE means disabled for inactivity) | Activate / Deactivate |
| Deleted | `delete` (TRUE means marked for deletion) | Delete / Undelete |
| Spammer | `spammer` (TRUE means SMTP submission blocked) | none; a password reset clears it |
| Recovery email | `recoveryEmail` | Set |
| Recovery phone | `recoveryPhone` | Set; *Generate new password and send by SMS* (only if a phone is set) |
| Storage | used / `quota` in MB, with % (`quota` is stored as `*:storage=<KB>`) | none |
| Secret Q/A | `secretQuestion` / `secretAnswer` (legacy) | none. **Not ported**: recovery contacts replace it. |
| Password | none | *Generate new password*: shows it on screen and clears `spammer` |
| Aliases | list | none |

**Generate new password:** 12 characters from
`0123456789!#$%abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ` (no ambiguous
`i l o I O`), written to `clearPassword`.

**SMS:** a POST to the Duo transactional API
(`https://app.duo.pt/transactional/<t>/message/<m>/send?telephone=…&password=…`,
basic auth). The old app always used transactional 19 / message 10 with the
clix.pt credentials, for every domain.

### 1.2 User preferences (Horde prefs "special" screens)

- **Change password** (`Changepass`). Already covered by Roundcube's `password`
  plugin. **Not ported.**
- **Recovery contacts** (`Alternatecontact`). Users edit their own
  `recoveryEmail` / `recoveryPhone`. Validation:
  - at least one of the two is required;
  - the email must be valid (an RFC 5321 regex);
  - the phone is reduced to digits, a leading `351` / `00351` is stripped, and
    the result must match `^9[0-9]{8}$` (a Portuguese mobile number).
  **Ported (§3).**

### 1.3 Registry API

`getRecoveryContact`, `getRecoveryEmail`, `getRecoveryTelephone`,
`getRecoveryCodes` / `setRecoveryCodes` (Horde pref `recovery_codes`), and
`updatePassword`. These served the Horde-side password-recovery flow, which
Roundcube's `reset_password` plugin now replaces (LDAP directory driver and
Redis code storage). **Not ported.**

### 1.4 Defects in the old code that the port must not repeat

1. **Predictable passwords.** `generatePassword()` seeds `rand()` from
   `md5(email)` plus the current day. Anyone who knows the address can predict
   the password for that day. Use `random_int()`.
2. **No per-domain check on changes.** `update.php` only checks "is some
   admin". An admin for `kanguru.pt` could modify any `portugalmail.pt` account.
3. **LDAP filter injection.** The email goes into the search filter
   unescaped, and the DN is built with a hardcoded mask.
4. **XSS.** Nothing in the templates is HTML-escaped, including LDAP data
   that users control, such as `recoveryEmail`.
5. **No CSRF protection** on the mutating POSTs.
6. **The SMS path differs from the on-screen reset.** It does not clear
   `spammer`, ignores the Duo response, and always reports success.
7. **Inconsistent phone normalisation.** The admin path keeps only digits and
   does not strip `351` or validate. The user path does both.
8. **Secrets in source.** The LDAP bind password, the Dovecot master password,
   the Duo credentials and the IMAP host are hardcoded or committed. In the new
   plugin they must all be config values. Consider rotating the master and Duo
   credentials, since they sit in the old repo's history.
9. Minor: a duplicate `setrecoverymail` case; the reset page title reads
   `$_REQUEST['email']`, which is unset there, so the title is empty; the
   generated SSHA hash is computed from an undefined variable and never used.

---

## 2. Support console

### 2.1 Placement

- Register a task: `$this->register_task('support')`. URL:
  `?_task=support&_action=…`.
- Show a taskbar button only to support admins. Follow the `sooma_sso`
  "Administration" link pattern: add content to `taskbar` in the `ready` hook,
  for non-framed HTML output.
- In every handler, refuse with HTTP 403 when the user is not an admin. Use
  `$rcmail->get_user_name()` as the identity.
- Templates: one set only, in `skins/elastic/templates/*.html` (plus
  `skins/elastic/*.css` if needed). This is an internal tool, so it gets no
  skin-specific variants. The skin directories must still exist, or Roundcube
  throws an error. Create `skins/sooma` and `skins/sooma-mobile` as relative
  symlinks to `elastic`, the same as `plugins/managesieve/skins/`:

  ```
  skins/elastic/
  skins/sooma        -> elastic
  skins/sooma-mobile -> elastic
  ```

### 2.2 Actions

| Action | Method | Purpose |
|---|---|---|
| `index` | GET | Search form |
| `search` | GET `_email` | Account page, or "not found" with the search form pre-filled |
| `set-active` | POST `_mail`, `_value` (0/1) | `accountActive` |
| `set-deleted` | POST `_mail`, `_value` (0/1) | `delete` |
| `set-recovery-email` | POST `_mail`, `_recovery_email` | `recoveryEmail`; an empty value removes the attribute |
| `set-recovery-phone` | POST `_mail`, `_recovery_phone` | `recoveryPhone`; an empty value removes the attribute |
| `reset-password` | POST `_mail` | New password shown on screen; `spammer` set to FALSE |
| `reset-password-sms` | POST `_mail` | New password sent by SMS; `spammer` set to FALSE |
| `set-paid-month` | POST `_mail` | `paymentActive` TRUE; `paymentData` extended by one month (§2.7) |
| `set-paid-year` | POST `_mail` | `paymentActive` TRUE; `paymentData` extended by one year (§2.7) |
| `set-unpaid` | POST `_mail` | `paymentActive` FALSE; `paymentData` set to now |

Rules for every POST action:

- `$rcmail->request_security_check()` for CSRF.
- Re-resolve `_mail` through LDAP. Never trust the posted value as a DN.
- Re-check the per-domain admin rule against the **resolved** account's domain.
- Write an audit line: `rcube::write_log('sooma_gratuito_support', "<admin> <action> <account> <ok|error>")`.
  Never log the password.
- Redirect back to `search` with a flash message (`$rcmail->output->show_message`
  after the redirect, or a session-stored notice).
- `reset-password` renders the result page directly and does not redirect, so
  the password never appears in a URL.

Delete / Deactivate / Mark as unpaid / password resets ask for confirmation in the browser
first, with a plain `confirm()`.

### 2.3 Account page

Same fields as §1.1, except the secret question and answer, plus:

- Escape everything (`rcube::Q()`).
- Dates use `$rcmail->format_date()` in the user's timezone. Missing data shows
  as "unknown".
- Quota is shown in MB with a percentage. If IMAP fails, show "unknown", not 0.
- Inactive accounts: no IMAP lookup; usage shows as "—".
- Show the spammer warning text prominently: "Account is marked as sending
  spam and cannot submit messages. Reset the password to restore submission
  rights."
- Disable the SMS button when there is no `recoveryPhone`.
- Do not read or show `secretQuestion` / `secretAnswer`.
- When the search went through an alias, say so: "`x@d` is an alias of `y@d`".

### 2.4 Password generation and storage

- 12 characters, same alphabet as before, using `random_int()`.
- Never store the plaintext (the old admin reset did). Hash and store the
  password exactly as the `password` plugin is configured for the current host:
  `password::hash_password($pass, $config['password_ldap_encodage'])`, written
  to the `password_ldap_pwattr` attribute. Load the `password` plugin's config
  (including the per-host `password.inc.php` override) rather than duplicating
  the values in this plugin's config, and do not duplicate the hashing code.

### 2.5 SMS

- Config `sooma_gratuito_support_duo` with keys `transactional`, `message`, `auth`.
  Override it per host in `config/<host>/sooma_gratuito_support.inc.php`, so each brand
  uses its own sender and template.
- Change the password and clear `spammer` first, then send the SMS.
- Check the HTTP status and JSON response. On failure, show and log the error
  and do not report success. Do not roll back the password change. Failures
  should be rare, and the admin can reset again or use the on-screen reset.

### 2.6 Recovery contact validation

Use one shared validator for both the admin and user paths:

- email: `rcube_utils::check_email()`;
- phone: same normalisation and `^9\d{8}$` rule as §1.2.

### 2.7 Payment

This feature is new; the old app had no payment fields.

- **Payment active?** (`paymentActive`, read-only): "Account marked as paid"
  (TRUE), "Account marked as unpaid" (FALSE), or "Account was never paid"
  (attribute missing).
- **Payment expiry date** (`paymentData`, a UNIX timestamp): shown as UTC ISO
  8601 (`2026-11-05T12:00:00Z`), or "undefined" when missing. Three buttons:
  - *Mark as paid for one month* / *for one year*: set `paymentActive` to TRUE.
    If `paymentData` is in the future, add the period to it. Otherwise (past
    or missing), set it to now plus the period. Periods are calendar months
    and years in UTC.
  - *Mark as unpaid*: set `paymentData` to now and `paymentActive` to FALSE.

---

## 3. Recovery contacts in Settings

- Add a section "Password recovery" through the `preferences_sections_list`,
  `preferences_list` and `preferences_save` hooks. Fields: recovery email and
  recovery mobile phone.
- Read and write the logged-in user's own entry (`get_user_name()`) in LDAP.
  Nothing is stored in Roundcube prefs: `reset_password` reads these
  attributes from LDAP.
- Validation as in §2.6, with at least one contact required. Validation
  errors abort the save with a message.
- Users on these hosts can already change their password in the `password`
  plugin's section. Do not add another password form.

---

## 4. LDAP layer

Add a small class `sooma_gratuito_support_ldap`. Model it on
`reset_password_directory_ldap`, but use `ldap_escape()` instead of
character stripping:

- `find_account(string $email): ?array`: alias resolution, then account lookup.
  Filters are built with `ldap_escape($v, '', LDAP_ESCAPE_FILTER)`. Returns
  normalised values (booleans, int quota in KB, `DateTimeImmutable`, the
  aliases list, the `dn` from the search result).
- `modify(array $account, array $changes)`: `ldap_mod_replace` on the
  account's own `dn`. A `null` value means `ldap_mod_del`. Booleans become
  `TRUE`/`FALSE`.
- Connect lazily, and raise errors as exceptions that the action handlers
  catch and show.

---

## 5. Configuration (`config.inc.php`)

- **LDAP:** `sooma_gratuito_support_ldap_host` (host[:port]), `_ldap_starttls`,
  `_ldap_bind_dn`, `_ldap_bind_password` and `_ldap_base_dn`. Each falls back to
  the matching `password` plugin setting (`password_ldap_host`, `_port`,
  `_starttls`, `_adminDN`, `_adminPW`, `_basedn`). The gratuito hosts already
  configure those for the same directory and the same writer, so no bind
  password needs to be copied.
- **IMAP quota:** `sooma_gratuito_support_imap_host` (defaults to `imap_host`),
  `_master_separator` (default `*`), `_master_user` and `_master_password`.
  Without a master user, usage shows as unknown.
- **Administrators:** `sooma_gratuito_support_administrators`, a map of
  `domain => [logins]` taken from the old `conf.php`: clix.pt, kanguru.pt,
  mail.optimus.pt, mail.pt, oniduo.pt, oninet.pt, oninetspeed.pt,
  optimus.clix.pt, portugalmail.pt and portugalmail.com.
  `nos.support@clix.pt` is listed for every domain except the two portugalmail
  ones.
- **SMS:** `sooma_gratuito_support_duo` = `['transactional' => …, 'message' => …,
  'auth' => 'user:password']`. The default is what the old app used for every
  domain (19 / 10, clix.pt credentials).

Enable the plugin by adding `sooma_gratuito_support` to `$config['plugins']` in the
three gratuito host configs (`config/correio.aeiou.pt/`,
`config/correio.portugalmail.pt/`, `config/webmail.clix.pt/`), and nowhere
else. It must be listed **before `sooma`**. `sooma::configuration_override()`
runs in `sooma`'s `init()` and loads `config/<host>/sooma_gratuito_support.inc.php`.
If this plugin initialised later, its own `load_config()` would overwrite
those per-host values.

---

## 6. Localization

Use `localization/en_US.inc` and `pt_PT.inc` (the default language is
`pt_PT`). Carry over the old English strings and add Portuguese.

---

## 7. Out of scope

- The Horde prefs `recovery_codes` and the registry API (§1.3).
- Searching by anything other than the exact address.
- Creating accounts or editing aliases.
- The secret question/answer (`secretQuestion` / `secretAnswer`), which recovery
  contacts supersede.
