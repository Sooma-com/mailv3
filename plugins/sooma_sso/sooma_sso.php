<?php
declare(strict_types=1);

/**
 * Sooma SSO Plugin for Roundcube
 *
 * Lets the Sooma subscription portals (portugalmail.pt, clix.pt,
 * xekmail.pt, ...) log a user straight into webmail right after they've
 * entered their password on the portal - without a cross-site form POST
 * (which Roundcube's CSRF protection correctly rejects) and without any
 * shared server-side store (the portals run in a DMZ with no route to
 * internal services such as Redis or the mail databases).
 *
 * Wire format
 * -----------
 * The portal encrypts a JSON payload with a key shared out-of-band with
 * this plugin (`sooma_sso_key` in config, 32 raw bytes, base64-encoded):
 *
 *   {"username": "user@domain.tld", "password": "...", "timestamp": 1700000000}
 *
 * using AES-256-GCM:
 *
 *   $iv = random_bytes(12);
 *   $ciphertext = openssl_encrypt($json, 'aes-256-gcm', $key, OPENSSL_RAW_DATA, $iv, $tag);
 *   $token = base64url_encode($iv . $tag . $ciphertext);
 *
 * The portal then auto-submits (client-side, top-level navigation - not
 * fetch/XHR, so no CORS is involved) a hidden HTML form with
 * method="POST" to:
 *
 *   https://<webmail-host>/?_task=login&_action=sso
 *
 * with a single field `_sso` holding the token. POST (rather than GET)
 * is deliberate: it keeps the password-bearing token out of browser
 * history, web server access logs and Referer headers.
 *
 * Session lookup for same-host apps
 * ----------------------------------
 * An application on this same host (Nexus, under /directory/) receives
 * the Roundcube session cookies and can ask who they belong to:
 *
 *   GET/POST https://<webmail-host>/?_task=login&_action=whoami
 *   Cookie: roundcube_sessid=...; roundcube_sessauth=...
 *
 * The reply is JSON, and the request carries no Roundcube CSRF token
 * (the caller is an API client, not the webmail UI):
 *
 *   200 {"username": "user@domain.tld"}
 *   401 {"username": null}
 *
 * Both cookies are required. `roundcube_sessid` selects the session;
 * `roundcube_sessauth` is checked with the same rules as a normal
 * authenticated request. A miss does not destroy the session.
 *
 * Administration link
 * -------------------
 * Once per session, on the first authenticated request after login,
 * the plugin asks the Sooma Directory whether this user may administer:
 *
 *   GET http://<sooma_sso_directory_address>/test_access/
 *   Cookie: roundcube_sessid=...; roundcube_sessauth=...
 *
 * `sooma_sso_directory_address` is a hostname or IP, with an optional
 * port (80 when omitted). The cookies are the ones Roundcube received
 * on that request. The response is application/json and a boolean.
 * true adds an "Administration" link to the task menu, pointing at
 * /directory/. false leaves the link out. A failed request is logged
 * and treated as false. The boolean is stored in the session, so the
 * directory is asked only once for that login.
 *
 * Security notes
 * --------------
 * - The token is a bearer credential valid for `sooma_sso_token_ttl`
 *   seconds (default 30). There is intentionally no server-side
 *   single-use tracking - that would need the shared store this design
 *   avoids. The short TTL, TLS transport and POST-not-GET delivery are
 *   the mitigations for replay.
 * - Any failure to decrypt/authenticate/parse the token, an
 *   out-of-window timestamp, or a decrypted password that the IMAP
 *   server rejects, is a hard failure: this plugin never falls back to
 *   the normal login form, it just terminates the request. The error
 *   page shown to the browser is generic (error code 600); details go
 *   only to the server log.
 *
 * @author Sérgio Carvalho <daf@sooma.com>
 *
 * Copyright (C) Sooma.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */
class sooma_sso extends rcube_plugin
{
    private const CIPHER  = 'aes-256-gcm';
    private const IV_LEN  = 12;
    private const TAG_LEN = 16;
    private const KEY_LEN = 32;

    /** Session flag: bool, set after the one directory access probe. */
    private const SESSION_ADMIN_ACCESS = 'sooma_sso_admin_access';

    /** Connect and total timeout, in seconds, for the access probe. */
    private const DIRECTORY_TIMEOUT_SEC = 5;

    private $sso_pending = false;
    private $sso_user;
    private $sso_pass;

    public function init()
    {
        $this->add_texts('localization/', false);
        $this->add_hook('startup', [$this, 'startup']);
        $this->add_hook('authenticate', [$this, 'authenticate']);
        $this->add_hook('login_failed', [$this, 'login_failed']);
        $this->add_hook('ready', [$this, 'ready']);
    }

    /**
     * Show the Administration task-menu link when this session may administer.
     *
     * `ready` runs only after the user is authenticated, so the probe
     * happens on the first request that follows login, when the browser
     * has already sent the new session cookies back.
     */
    public function ready($args)
    {
        if (empty($_SESSION['user_id']) || !$this->directory_admin_access()) {
            return $args;
        }

        $output = rcmail::get_instance()->output;
        if ($output && $output->type === 'html' && empty($output->framed)) {
            // Written by hand rather than add_button(). The template
            // pass fix_paths() rewrites any href="/..." onto the skin
            // directory, so href="/directory/" was sent as
            // skins/sooma/directory/. &#47; is a slash the rewriter
            // does not recognize; the browser decodes it to
            // href="/directory/".
            $this->api->add_content(
                '<a href="&#47;directory/" class="directory" id="sooma-administration" role="button">'
                . '<span class="inner">' . html::quote($this->gettext('administration')) . '</span></a>',
                'taskbar'
            );
        }

        return $args;
    }

    public function startup($args)
    {
        if ($args['action'] === 'whoami') {
            $this->reply_session_user();
        }

        if ($args['task'] !== 'login' || $args['action'] !== 'sso') {
            return $args;
        }

        $this->load_config();

        $token = rcube_utils::get_input_string('_sso', rcube_utils::INPUT_POST);
        if (!$token) {
            $this->fail('missing _sso token');
        }

        [$this->sso_user, $this->sso_pass] = $this->decrypt_token($token);
        $this->sso_pending = true;

        // Start from a clean session before re-authenticating, same as
        // core does for an ordinary (CSRF-token-validated) re-login.
        if (!empty($_SESSION['user_id'])) {
            rcmail::get_instance()->kill_session();
        }

        $args['action'] = 'login';

        return $args;
    }

    public function authenticate($args)
    {
        if (!$this->sso_pending) {
            return $args;
        }

        $args['user']        = $this->sso_user;
        $args['pass']        = $this->sso_pass;
        $args['valid']       = true;
        $args['cookiecheck'] = false;

        return $args;
    }

    public function login_failed($args)
    {
        if ($this->sso_pending) {
            // The portal already verified this password; landing here
            // means something is inconsistent (stale token, password
            // changed since, backend misconfiguration, ...). No graceful
            // recovery - fail hard rather than show a confusing login
            // form or leak which part of the credential was wrong.
            $this->fail('IMAP login rejected decrypted SSO credentials for user ' . $args['user']);
        }

        return $args;
    }

    /**
     * Whether the current session may open /directory/.
     *
     * The directory is contacted at most once; the boolean lives in the
     * session until logout.
     */
    private function directory_admin_access(): bool
    {
        if (array_key_exists(self::SESSION_ADMIN_ACCESS, $_SESSION)) {
            return $_SESSION[self::SESSION_ADMIN_ACCESS] === true;
        }

        $allowed = $this->query_directory_access();
        $_SESSION[self::SESSION_ADMIN_ACCESS] = $allowed;

        return $allowed;
    }

    /**
     * GET /test_access/ and read its JSON boolean.
     *
     * Any transport, HTTP, content-type, or body problem is logged and
     * reported as "no access", so webmail keeps working.
     */
    private function query_directory_access(): bool
    {
        if (!function_exists('curl_init')) {
            $this->log_directory_error('the curl extension is not available');
            return false;
        }

        $this->load_config();

        $rcmail  = rcmail::get_instance();
        $address = $rcmail->config->get('sooma_sso_directory_address', '');
        if (!is_string($address)) {
            $address = '';
        }

        $url = self::directory_test_access_url($address);
        if ($url === null) {
            $this->log_directory_error('sooma_sso_directory_address is missing or not a host[:port]');
            return false;
        }

        $cookie = $this->session_cookie_header();
        if ($cookie === null) {
            $this->log_directory_error('roundcube_sessid and roundcube_sessauth were not both present on the request');
            return false;
        }

        $ch = curl_init($url);
        if ($ch === false) {
            $this->log_directory_error('failed to initialize GET ' . $url);
            return false;
        }

        curl_setopt_array($ch, [
            CURLOPT_HTTPGET        => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_CONNECTTIMEOUT => self::DIRECTORY_TIMEOUT_SEC,
            CURLOPT_TIMEOUT        => self::DIRECTORY_TIMEOUT_SEC,
            CURLOPT_COOKIE         => $cookie,
            CURLOPT_HTTPHEADER     => ['Accept: application/json'],
        ]);

        $body = curl_exec($ch);
        if ($body === false) {
            $error = curl_error($ch);
            curl_close($ch);
            $this->log_directory_error('GET ' . $url . ' failed: ' . $error);
            return false;
        }

        $status       = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $content_type = (string) curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
        curl_close($ch);

        if ($status < 200 || $status >= 300) {
            $this->log_directory_error('GET ' . $url . ' returned HTTP ' . $status);
            return false;
        }

        if (!preg_match('#^application/json\b#i', $content_type)) {
            $shown = $content_type === '' ? '(none)' : $content_type;
            $this->log_directory_error('GET ' . $url . ' returned content type ' . $shown);
            return false;
        }

        $decoded = json_decode($body, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            $this->log_directory_error('GET ' . $url . ' failed to decode JSON: ' . json_last_error_msg());
            return false;
        }
        if (!is_array($decoded) || !isset($decoded['success'])) {
            $this->log_directory_error('GET ' . $url . ' did not return a Sooma API response');
            return false;
        }
        if (!$decoded['success']) {
            $this->log_directory_error('GET ' . $url . ' returned unsuccessful response');
            return false;
        }
        if (!is_bool($decoded['data'])) {
            $this->log_directory_error('GET ' . $url . ' returned data that is not a boolean');
            return false;
        }

        return $decoded['data'];
    }

    /**
     * Build http://host:port/test_access/ from a host or host:port address.
     * Port defaults to 80. Returns null when the address cannot be used.
     */
    private static function directory_test_access_url(string $address): ?string
    {
        $address = trim($address);
        if ($address === '') {
            return null;
        }

        $host = $address;
        $port = 80;

        if ($address[0] === '[') {
            if (!preg_match('/^\[([0-9A-Fa-f:.]+)\](?::(\d{1,5}))?$/', $address, $m)) {
                return null;
            }
            $host = '[' . $m[1] . ']';
            if (isset($m[2]) && $m[2] !== '') {
                $port = (int) $m[2];
            }
        }
        else if (!preg_match('/^[A-Za-z0-9._:-]+$/', $address)) {
            return null;
        }
        else if (substr_count($address, ':') === 1) {
            [$host, $port_str] = explode(':', $address, 2);
            if ($host === '' || !preg_match('/^\d{1,5}$/', $port_str)) {
                return null;
            }
            $port = (int) $port_str;
        }
        else if (substr_count($address, ':') > 1) {
            // Bare IPv6, no port. Anything else with several colons is rejected.
            if (!preg_match('/^[0-9A-Fa-f:.]+$/', $address)) {
                return null;
            }
            $host = '[' . $address . ']';
        }

        if ($port < 1 || $port > 65535) {
            return null;
        }

        return 'http://' . $host . ':' . $port . '/directory/test_access/';
    }

    /**
     * Cookie header carrying the session cookies this request received.
     * Names follow session_name / session_auth_name, which default to
     * roundcube_sessid and roundcube_sessauth.
     */
    private function session_cookie_header(): ?string
    {
        $rcmail = rcmail::get_instance();
        $names  = [
            (string) ($rcmail->config->get('session_name') ?: 'roundcube_sessid'),
            (string) ($rcmail->config->get('session_auth_name') ?: 'roundcube_sessauth'),
        ];

        $pairs = [];
        foreach ($names as $name) {
            if (!preg_match('/^[A-Za-z0-9_]+$/', $name)) {
                return null;
            }

            $value = $_COOKIE[$name] ?? null;
            if (!is_string($value) || $value === '' || preg_match('/[\r\n;]/', $value)) {
                return null;
            }

            $pairs[] = $name . '=' . $value;
        }

        return implode('; ', $pairs);
    }

    /**
     * Log a directory access-check failure and keep going.
     */
    private function log_directory_error(string $message): void
    {
        rcube::raise_error([
            'code'    => 600,
            'type'    => 'php',
            'message' => 'sooma_sso: directory access check failed: ' . $message,
        ], true, false);
    }

    /**
     * Identify the user behind the Roundcube session cookies and exit.
     *
     * Runs from the startup hook, before index.php's CSRF check, because
     * the API client has the session cookies but not a request token.
     */
    private function reply_session_user(): void
    {
        $rcmail   = rcmail::get_instance();
        $username = null;

        // Read-only. A write here would race the user's own webmail
        // requests, and a failed lookup must not log them out.
        if ($rcmail->session) {
            $rcmail->session->nowrite = true;
        }
        $rcmail->session->set_ip_check(false); // Request is expected to come from a different IP
        if (
            !empty($_SESSION['user_id'])
            && isset($_SESSION['username'])
            && is_string($_SESSION['username'])
            && $_SESSION['username'] !== ''
            && $rcmail->session
            && $rcmail->session->check_auth()
        ) {
            $username = $_SESSION['username'];
        }

        $this->json_reply(
            $username === null ? 401 : 200,
            ['username' => $username]
        );
    }

    /**
     * @param array<string, mixed> $payload
     */
    private function json_reply(int $status, array $payload): void
    {
        while (ob_get_level() > 0) {
            ob_end_clean();
        }

        http_response_code($status);
        header('Content-Type: application/json; charset=UTF-8');
        header('X-Content-Type-Options: nosniff');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    /**
     * @return array{0: string, 1: string} [username, password]
     */
    private function decrypt_token(string $token): array
    {
        $rcmail  = rcmail::get_instance();
        $key_b64 = $rcmail->config->get('sooma_sso_key');
        $ttl     = (int) $rcmail->config->get('sooma_sso_token_ttl', 30);

        $key = $key_b64 ? base64_decode((string) $key_b64, true) : false;
        if ($key === false || strlen($key) !== self::KEY_LEN) {
            $this->fail('sooma_sso_key is not configured with a valid 32-byte base64 key');
        }

        $raw = self::base64url_decode($token);
        if ($raw === false || strlen($raw) <= self::IV_LEN + self::TAG_LEN) {
            $this->fail('malformed token');
        }

        $iv         = substr($raw, 0, self::IV_LEN);
        $tag        = substr($raw, self::IV_LEN, self::TAG_LEN);
        $ciphertext = substr($raw, self::IV_LEN + self::TAG_LEN);

        $json = openssl_decrypt($ciphertext, self::CIPHER, $key, OPENSSL_RAW_DATA, $iv, $tag);
        if ($json === false) {
            $this->fail('token authentication failed (bad key or tampered/corrupt token)');
        }

        $payload = json_decode($json, true);
        if (
            !is_array($payload)
            || empty($payload['username']) || !is_string($payload['username'])
            || !isset($payload['password']) || !is_string($payload['password'])
            || !isset($payload['timestamp']) || !is_numeric($payload['timestamp'])
        ) {
            $this->fail('token payload missing or malformed required fields');
        }

        $skew = abs(time() - (int) $payload['timestamp']);
        if ($skew > $ttl) {
            $this->fail("token timestamp out of range (skew={$skew}s, ttl={$ttl}s)");
        }

        return [$payload['username'], $payload['password']];
    }

    /**
     * @return string|false
     */
    private static function base64url_decode(string $data)
    {
        return base64_decode(strtr($data, '-_', '+/'), true);
    }

    /**
     * Log the real reason server-side and terminate the request with a
     * generic error page. Never surface $message to the client.
     */
    private function fail(string $message): void
    {
        rcube::raise_error([
            'code'    => 600,
            'type'    => 'php',
            'message' => 'sooma_sso: ' . $message,
        ], true, true);
    }
}
