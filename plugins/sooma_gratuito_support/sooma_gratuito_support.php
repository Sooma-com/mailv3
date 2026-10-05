<?php
declare(strict_types=1);

require_once __DIR__ . '/lib/sooma_gratuito_support_ldap.php';

/**
 * Sooma gratuito support plugin
 *
 * Port of the Horde "support" application, for the gratuito hosts only:
 *  - a support console (task "support") where staff look up an account in
 *    the LDAP directory and fix common problems;
 *  - a Settings section where users set their own password recovery contacts.
 *
 * See SPEC.md for the full description.
 *
 * @author Sérgio Carvalho <sergio.carvalho@sooma.com>
 *
 * Copyright (C) Sooma.com
 */
class sooma_gratuito_support extends rcube_plugin
{
    public $task = '?(?!login|logout).*';
    public $noajax = true;

    private const PASSWORD_CHARSET = '0123456789!#$%abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
    private const PASSWORD_LENGTH = 12;
    private const SESSION_NOTICE = 'sooma_gratuito_support_notice';
    private const PREFS_SECTION = 'passwordrecovery';
    private const UPDATE_ACTIONS = [
        'set-active', 'set-deleted', 'set-recovery-email', 'set-recovery-phone',
        'reset-password', 'reset-password-sms', 'set-paid-month', 'set-paid-year', 'set-unpaid',
    ];
    private const HTTP_TIMEOUT_SEC = 10;

    private rcmail $rc;
    private ?sooma_gratuito_support_ldap $ldap = null;
    private string $body = '';

    public function init()
    {
        $this->rc = rcmail::get_instance();
        $this->load_config();
        $this->add_texts('localization/');

        $this->register_task('support');
        $this->register_action('index', [$this, 'action_index']);
        $this->register_action('search', [$this, 'action_search']);
        foreach (self::UPDATE_ACTIONS as $action) {
            $this->register_action($action, [$this, 'action_update']);
        }

        $this->add_hook('ready', [$this, 'ready']);

        if ($this->rc->task == 'settings') {
            $this->add_hook('preferences_sections_list', [$this, 'preferences_sections_list']);
            $this->add_hook('preferences_list', [$this, 'preferences_list']);
            $this->add_hook('preferences_save', [$this, 'preferences_save']);
        }
    }

    /**
     * Add the taskbar button for support administrators.
     */
    public function ready($args)
    {
        $output = $this->rc->output;
        if (empty($_SESSION['user_id']) || !$this->is_admin() || $output->type !== 'html' || !empty($output->framed)) {
            return $args;
        }

        $this->include_stylesheet($this->local_skin_path() . '/sooma_gratuito_support.css');
        $this->api->add_content(
            html::a(
                [
                    'href'  => $this->rc->url(['_task' => 'support', '_action' => 'index']),
                    'class' => 'support' . ($this->rc->task == 'support' ? ' selected' : ''),
                    'id'    => 'sooma-gratuito-support',
                    'role'  => 'button',
                ],
                html::span('inner', rcube::Q($this->gettext('support')))
            ),
            'taskbar'
        );

        return $args;
    }

    // ---------------------------------------------------------------------
    // Support console

    public function action_index()
    {
        $this->assert_admin();
        $this->render($this->gettext('emailsupport'), html::p(null, rcube::Q($this->gettext('searchintro'))) . $this->search_form(''));
    }

    public function action_search()
    {
        $this->assert_admin();
        $email = trim(rcube_utils::get_input_string('_email', rcube_utils::INPUT_GET));

        try {
            $account = $this->find_managed_account($email);
        }
        catch (Exception $e) {
            $this->log_error('search ' . $email . ': ' . $e->getMessage());
            $this->rc->output->show_message($this->gettext(['name' => 'directoryerror', 'vars' => ['error' => $e->getMessage()]]), 'error');
            $this->render($this->gettext('emailsupport'), $this->search_form($email));
        }

        if ($account === null) {
            $this->render(
                $this->gettext('nonexistentaccount'),
                html::p(null, rcube::Q($this->gettext('accountnotfound'))) . $this->search_form($email)
            );
        }

        $this->render($this->gettext('accountdetails'), $this->search_form('') . $this->account_details($account));
    }

    /**
     * Handler for every state-changing POST action.
     */
    public function action_update()
    {
        $this->assert_admin();
        $this->rc->request_security_check();

        $action = $this->rc->action;
        $mail   = rcube_utils::get_input_string('_mail', rcube_utils::INPUT_POST);

        try {
            $account = $this->find_managed_account($mail);
        }
        catch (Exception $e) {
            $this->audit($action, $mail, 'error ' . $e->getMessage());
            $this->redirect_to_account($mail, 'error', 'directoryerror', ['error' => $e->getMessage()]);
        }
        if ($account === null) {
            $this->audit($action, $mail, 'error account not found or not managed');
            $this->redirect_to_account($mail, 'error', 'accountnotfound');
        }
        $mail = $account['mail'];

        try {
            switch ($action) {
            case 'set-active':
                $this->ldap()->modify($account, ['accountActive' => $this->posted_flag()]);
                break;

            case 'set-deleted':
                $this->ldap()->modify($account, ['delete' => $this->posted_flag()]);
                break;

            case 'set-recovery-email':
                $email = trim(rcube_utils::get_input_string('_recovery_email', rcube_utils::INPUT_POST));
                if ($email !== '' && !self::valid_email($email)) {
                    $this->audit($action, $mail, 'error invalid email');
                    $this->redirect_to_account($mail, 'error', 'invalidemail');
                }
                $this->ldap()->modify($account, ['recoveryEmail' => $email === '' ? null : $email]);
                break;

            case 'set-recovery-phone':
                $phone = self::normalise_phone(rcube_utils::get_input_string('_recovery_phone', rcube_utils::INPUT_POST));
                if ($phone === null) {
                    $this->audit($action, $mail, 'error invalid phone');
                    $this->redirect_to_account($mail, 'error', 'invalidphone');
                }
                $this->ldap()->modify($account, ['recoveryPhone' => $phone === '' ? null : $phone]);
                break;

            case 'reset-password':
                $password = $this->reset_password($account);
                $this->audit($action, $mail, 'ok');
                $this->render_new_password($account, $password);
                break;

            case 'reset-password-sms':
                $this->reset_password_sms($account);
                break;

            case 'set-paid-month':
            case 'set-paid-year':
                $this->ldap()->modify($account, [
                    'paymentActive' => true,
                    'paymentData'   => (string) self::extended_payment_expiry(
                        $account['payment_expiry'],
                        $action == 'set-paid-month' ? '+1 month' : '+1 year'
                    ),
                ]);
                break;

            case 'set-unpaid':
                $this->ldap()->modify($account, ['paymentActive' => false, 'paymentData' => (string) time()]);
                break;
            }
        }
        catch (Exception $e) {
            $this->audit($action, $mail, 'error ' . $e->getMessage());
            $this->redirect_to_account($mail, 'error', 'changefailed', ['error' => $e->getMessage()]);
        }

        $this->audit($action, $mail, 'ok');
        $this->redirect_to_account($mail, 'confirmation', 'changesuccessful');
    }

    private function reset_password_sms(array $account): void
    {
        $mail = $account['mail'];
        if (empty($account['recovery_phone'])) {
            $this->audit('reset-password-sms', $mail, 'error no recovery phone');
            $this->redirect_to_account($mail, 'error', 'norecoveryphone');
        }

        $duo = (array) $this->rc->config->get('sooma_gratuito_support_duo', []);
        if (empty($duo['transactional']) || empty($duo['message']) || empty($duo['auth'])) {
            $this->audit('reset-password-sms', $mail, 'error SMS not configured');
            $this->redirect_to_account($mail, 'error', 'smsnotconfigured');
        }

        $password = $this->reset_password($account);

        $error = $this->send_sms($duo, $account['recovery_phone'], $password);
        if ($error !== null) {
            // The password has changed already. Report the failure; the admin can reset again.
            $this->audit('reset-password-sms', $mail, 'error password changed, SMS failed: ' . $error);
            $this->redirect_to_account($mail, 'error', 'smsfailed', ['error' => $error]);
        }

        $this->audit('reset-password-sms', $mail, 'ok');
        $this->redirect_to_account($mail, 'confirmation', 'passwordsentbysms', ['phone' => $account['recovery_phone']]);
    }

    /**
     * Set a new random password and clear the spammer flag.
     *
     * Hashing and storage follow the password plugin's LDAP driver configuration.
     */
    private function reset_password(array $account): string
    {
        if (!class_exists('password')) {
            throw new Exception('the password plugin is not loaded');
        }

        $password = '';
        for ($i = 0; $i < self::PASSWORD_LENGTH; $i++) {
            $password .= self::PASSWORD_CHARSET[random_int(0, strlen(self::PASSWORD_CHARSET) - 1)];
        }

        $hashes = [];
        foreach (explode('+', (string) $this->rc->config->get('password_ldap_encodage', 'md5-crypt')) as $method) {
            if ($hash = password::hash_password($password, $method)) {
                $hashes[] = $hash;
            }
        }
        if (empty($hashes)) {
            throw new Exception('unable to hash the password with ' . $this->rc->config->get('password_ldap_encodage'));
        }

        $changes = [
            $this->rc->config->get('password_ldap_pwattr', 'userPassword') => $hashes,
            'spammer' => false,
        ];
        if ($lchattr = $this->rc->config->get('password_ldap_lchattr')) {
            $changes[$lchattr] = (string) (int) (time() / 86400);
        }
        $this->ldap()->modify($account, $changes);

        return $password;
    }

    /**
     * @return string|null Error description, or null when the SMS was accepted
     */
    private function send_sms(array $duo, string $phone, string $password): ?string
    {
        if (!function_exists('curl_init')) {
            return 'the curl extension is not available';
        }

        $url = sprintf(
            'https://app.duo.pt/transactional/%d/message/%d/send?%s',
            $duo['transactional'],
            $duo['message'],
            http_build_query(['telephone' => $phone, 'password' => $password])
        );
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_USERPWD        => $duo['auth'],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_CONNECTTIMEOUT => self::HTTP_TIMEOUT_SEC,
            CURLOPT_TIMEOUT        => self::HTTP_TIMEOUT_SEC,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'Accept: application/json'],
        ]);
        $body = curl_exec($ch);
        if ($body === false) {
            $error = curl_error($ch);
            curl_close($ch);

            return $error;
        }
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($status < 200 || $status >= 300) {
            return 'HTTP ' . $status;
        }
        $decoded = json_decode((string) $body, true);
        if (is_array($decoded) && isset($decoded['success']) && !$decoded['success']) {
            return 'rejected: ' . substr((string) $body, 0, 200);
        }

        return null;
    }

    private function render_new_password(array $account, string $password): void
    {
        $content = html::p(null, rcube::Q($this->gettext(['name' => 'newpasswordis', 'vars' => ['mail' => $account['mail']]])))
            . html::div('sgs-password', rcube::Q($password))
            . html::p(null, html::a(
                ['href' => $this->account_url($account['mail']), 'class' => 'button'],
                rcube::Q($this->gettext('backtoaccount'))
            ));

        $this->render($this->gettext('passwordset'), $content);
    }

    // ---------------------------------------------------------------------
    // Rendering

    /**
     * Send the page and exit.
     */
    private function render(string $title, string $content): void
    {
        if (!empty($_SESSION[self::SESSION_NOTICE])) {
            [$type, $message] = $_SESSION[self::SESSION_NOTICE];
            $this->rc->output->show_message($message, $type);
            $this->rc->session->remove(self::SESSION_NOTICE);
        }

        $this->include_stylesheet($this->local_skin_path() . '/sooma_gratuito_support.css');
        $this->include_script('sooma_gratuito_support.js');
        $this->body = html::div('sgs-content', html::tag('h2', null, rcube::Q($title)) . $content);
        $this->rc->output->set_pagetitle($title);
        $this->rc->output->add_handlers(['plugin.supportbody' => [$this, 'body']]);
        $this->rc->output->send('sooma_gratuito_support.support');
        exit;
    }

    public function body()
    {
        return $this->body;
    }

    private function search_form(string $email): string
    {
        $input = new html_inputfield([
            'name'        => '_email',
            'id'          => 'sgs-search-email',
            'type'        => 'email',
            'class'       => 'form-control',
            'placeholder' => $this->gettext('emailplaceholder'),
            'required'    => true,
        ]);

        return html::tag('form', ['method' => 'get', 'action' => './', 'class' => 'sgs-search'],
            (new html_hiddenfield(['name' => '_task', 'value' => 'support']))->show()
            . (new html_hiddenfield(['name' => '_action', 'value' => 'search']))->show()
            . html::label('sgs-search-email', rcube::Q($this->gettext('email')))
            . $input->show($email)
            . html::tag('button', ['type' => 'submit', 'class' => 'button mainaction search'], rcube::Q($this->gettext('search')))
        );
    }

    private function account_details(array $account): string
    {
        $mail    = $account['mail'];
        $unknown = $this->gettext('unknown');
        $rows    = [];

        $address = rcube::Q($mail);
        if ($account['searched_alias']) {
            $address .= html::div('sgs-note', rcube::Q($this->gettext([
                'name' => 'aliasof', 'vars' => ['alias' => $account['searched_alias'], 'account' => $mail],
            ])));
        }
        $rows[] = [$this->gettext('address'), $address];

        $rows[] = [$this->gettext('creation'), rcube::Q($this->gettext(['name' => 'createdon', 'vars' => [
            'date' => $account['creation_time'] ? $this->rc->format_date($account['creation_time'], 'Y-m-d H:i:s') : $unknown,
            'ip'   => $account['registration_ip'] ?? $unknown,
        ]]))];

        $rows[] = [
            $this->gettext('active'),
            rcube::Q($this->gettext($account['active'] ? 'activeyes' : 'activeno'))
            . $this->action_form('set-active', $mail, $account['active'] ? 'deactivate' : 'activate',
                ['_value' => $account['active'] ? '0' : '1'], $account['active'] ? 'confirmdeactivate' : null),
        ];

        $rows[] = [
            $this->gettext('deleted'),
            rcube::Q($this->gettext($account['deleted'] ? 'deletedyes' : 'deletedno'))
            . $this->action_form('set-deleted', $mail, $account['deleted'] ? 'undelete' : 'delete',
                ['_value' => $account['deleted'] ? '0' : '1'], $account['deleted'] ? null : 'confirmdelete'),
        ];

        $rows[] = [
            $this->gettext('spammer'),
            $account['spammer']
                ? html::div('sgs-warning', rcube::Q($this->gettext('spammeryes')))
                : rcube::Q($this->gettext('spammerno')),
        ];

        $rows[] = [
            $this->gettext('recoveryemail'),
            rcube::Q($account['recovery_email'] ?? $this->gettext('notset'))
            . $this->action_form('set-recovery-email', $mail, 'setrecoveryemail', [], null, [
                'name' => '_recovery_email', 'type' => 'email', 'value' => $account['recovery_email'] ?? '',
                'placeholder' => $this->gettext('emailplaceholder'),
            ]),
        ];

        $rows[] = [
            $this->gettext('recoveryphone'),
            rcube::Q($account['recovery_phone'] ?? $this->gettext('notset'))
            . $this->action_form('set-recovery-phone', $mail, 'setrecoveryphone', [], null, [
                'name' => '_recovery_phone', 'type' => 'tel', 'value' => $account['recovery_phone'] ?? '',
                'placeholder' => $this->gettext('phoneplaceholder'),
            ]),
        ];

        if ($account['payment_active'] === null) {
            $payment_status = 'paymentnever';
        }
        else {
            $payment_status = $account['payment_active'] ? 'paymentpaid' : 'paymentunpaid';
        }
        $rows[] = [$this->gettext('paymentactive'), rcube::Q($this->gettext($payment_status))];

        $rows[] = [
            $this->gettext('paymentexpiry'),
            rcube::Q($account['payment_expiry'] === null
                ? $this->gettext('undefined')
                : gmdate('Y-m-d\\TH:i:s\\Z', $account['payment_expiry']))
            . html::div('sgs-buttons',
                $this->action_form('set-paid-month', $mail, 'markpaidmonth')
                . $this->action_form('set-paid-year', $mail, 'markpaidyear')
                . $this->action_form('set-unpaid', $mail, 'markunpaid', [], 'confirmmarkunpaid')
            ),
        ];

        $rows[] = [$this->gettext('storage'), rcube::Q($this->storage_text($account))];

        $rows[] = [
            $this->gettext('password'),
            $this->action_form('reset-password', $mail, 'generatepassword', [], 'confirmresetpassword')
            . $this->action_form('reset-password-sms', $mail, 'generatepasswordsms', [], 'confirmresetpasswordsms',
                null, empty($account['recovery_phone'])),
        ];

        $rows[] = [
            $this->gettext('aliases'),
            $account['aliases']
                ? html::tag('ul', null, implode('', array_map(function ($alias) {
                    return html::tag('li', null, rcube::Q($alias));
                }, $account['aliases'])))
                : rcube::Q($this->gettext('noaliases')),
        ];

        $table = new html_table(['cols' => 2, 'class' => 'propform sgs-account']);
        foreach ($rows as [$label, $value]) {
            $table->add('title', rcube::Q($label));
            $table->add(null, $value);
        }

        return $table->show();
    }

    /**
     * A small POST form for one account action.
     *
     * @param array      $hidden  extra hidden fields
     * @param string     $confirm label of the confirmation question, if any
     * @param array|null $input   optional text input attributes (name, type, value, placeholder)
     */
    private function action_form(string $action, string $mail, string $label, array $hidden = [], ?string $confirm = null,
        ?array $input = null, bool $disabled = false): string
    {
        $content = (new html_hiddenfield(['name' => '_mail', 'value' => $mail]))->show();
        foreach ($hidden as $name => $value) {
            $content .= (new html_hiddenfield(['name' => $name, 'value' => $value]))->show();
        }
        if ($input) {
            $value = $input['value'];
            unset($input['value']);
            $content .= (new html_inputfield($input + ['class' => 'form-control']))->show($value);
        }
        $content .= html::tag('button', ['type' => 'submit', 'class' => 'button', 'disabled' => $disabled],
            rcube::Q($this->gettext($label)));

        $attrib = [
            'method' => 'post',
            'action' => $this->rc->url(['_task' => 'support', '_action' => $action]),
            'class'  => 'sgs-action',
        ];
        if ($confirm) {
            $attrib['data-confirm'] = $this->gettext($confirm);
        }

        return html::tag('form', $attrib, $content);
    }

    private function storage_text(array $account): string
    {
        if (!$account['active']) {
            return $this->gettext('storageinactive');
        }

        $used = $this->imap_usage_kb($account['mail']);
        $vars = [
            'used'  => $used === null ? $this->gettext('unknown') : (string) round($used / 1024),
            'total' => $account['quota_kb'] === null ? $this->gettext('unknown') : (string) round($account['quota_kb'] / 1024),
        ];
        if ($used !== null && $account['quota_kb']) {
            $vars['percent'] = (string) round(100 * $used / $account['quota_kb']);

            return $this->gettext(['name' => 'storageusage', 'vars' => $vars]);
        }

        return $this->gettext(['name' => 'storageusagenopercent', 'vars' => $vars]);
    }

    /**
     * Read INBOX storage usage through the Dovecot master user.
     *
     * @return int|null Usage in KB, or null when it can't be read
     */
    private function imap_usage_kb(string $mail): ?int
    {
        $master_user = (string) $this->rc->config->get('sooma_gratuito_support_master_user', '');
        $master_password = (string) $this->rc->config->get('sooma_gratuito_support_master_password', '');
        if ($master_user === '' || $master_password === '') {
            return null;
        }

        $host = $this->rc->config->get('sooma_gratuito_support_imap_host') ?: $this->rc->config->get('imap_host');
        if (is_array($host)) {
            $host = array_key_first($host);
        }
        [$host, $scheme, $port] = rcube_utils::parse_host_uri((string) $host, 143, 993);
        $ssl_mode = in_array($scheme, ['ssl', 'imaps']) ? 'ssl' : ($scheme === 'tls' ? 'tls' : null);

        $imap = new rcube_imap_generic();
        $login = $mail . $this->rc->config->get('sooma_gratuito_support_master_separator', '*') . $master_user;
        if (!$imap->connect($host, $login, $master_password, ['port' => $port, 'ssl_mode' => $ssl_mode, 'timeout' => 5])) {
            $this->log_error('IMAP quota lookup for ' . $mail . ' failed: ' . $imap->error);

            return null;
        }
        $quota = $imap->getQuota('INBOX');
        $imap->closeConnection();

        return isset($quota['used']) ? (int) $quota['used'] : null;
    }

    // ---------------------------------------------------------------------
    // Settings: password recovery contacts

    public function preferences_sections_list($args)
    {
        $args['list'][self::PREFS_SECTION] = [
            'id'      => self::PREFS_SECTION,
            'section' => $this->gettext('recoverysection'),
        ];

        return $args;
    }

    public function preferences_list($args)
    {
        if ($args['section'] != self::PREFS_SECTION) {
            return $args;
        }

        $args['blocks']['main']['name'] = $this->gettext('recoverycontacts');

        try {
            $account = $this->ldap()->find_account($this->rc->get_user_name());
        }
        catch (Exception $e) {
            $this->log_error('read recovery contacts of ' . $this->rc->get_user_name() . ': ' . $e->getMessage());
            $account = null;
        }
        if ($account === null || $account['searched_alias']) {
            $args['blocks']['main']['options']['unavailable'] = [
                'content' => rcube::Q($this->gettext('recoveryunavailable')),
            ];

            return $args;
        }

        $email = new html_inputfield(['name' => '_recovery_email', 'id' => 'rcmfd_recovery_email', 'type' => 'email', 'size' => 40]);
        $phone = new html_inputfield(['name' => '_recovery_phone', 'id' => 'rcmfd_recovery_phone', 'type' => 'tel', 'size' => 40,
            'placeholder' => $this->gettext('phoneplaceholder')]);

        $args['blocks']['main']['options']['recovery_email'] = [
            'title'   => html::label('rcmfd_recovery_email', rcube::Q($this->gettext('recoveryemail'))),
            'content' => $email->show($account['recovery_email'] ?? ''),
        ];
        $args['blocks']['main']['options']['recovery_phone'] = [
            'title'   => html::label('rcmfd_recovery_phone', rcube::Q($this->gettext('recoveryphone'))),
            'content' => $phone->show($account['recovery_phone'] ?? ''),
        ];

        return $args;
    }

    public function preferences_save($args)
    {
        if ($args['section'] != self::PREFS_SECTION) {
            return $args;
        }

        // Nothing goes to Roundcube prefs: the contacts live in LDAP, where reset_password reads them
        $args['abort']  = true;
        $args['result'] = false;

        $email = trim(rcube_utils::get_input_string('_recovery_email', rcube_utils::INPUT_POST));
        $phone = self::normalise_phone(rcube_utils::get_input_string('_recovery_phone', rcube_utils::INPUT_POST));

        if ($email === '' && $phone === '') {
            $args['message'] = 'sooma_gratuito_support.recoverycontactrequired';

            return $args;
        }
        if ($email !== '' && !self::valid_email($email)) {
            $args['message'] = 'sooma_gratuito_support.invalidemail';

            return $args;
        }
        if ($phone === null) {
            $args['message'] = 'sooma_gratuito_support.invalidphone';

            return $args;
        }

        try {
            $account = $this->ldap()->find_account($this->rc->get_user_name());
            if ($account === null || $account['searched_alias']) {
                throw new Exception('account not found');
            }
            $this->ldap()->modify($account, [
                'recoveryEmail' => $email === '' ? null : $email,
                'recoveryPhone' => $phone === '' ? null : $phone,
            ]);
            $args['result'] = true;
        }
        catch (Exception $e) {
            $this->log_error('save recovery contacts of ' . $this->rc->get_user_name() . ': ' . $e->getMessage());
            $args['message'] = 'sooma_gratuito_support.recoverysaveerror';
        }

        return $args;
    }

    // ---------------------------------------------------------------------
    // Helpers

    /**
     * Normalise a Portuguese mobile number: digits only, without the 351 country code.
     *
     * @return string|null Normalised number, '' when empty, null when invalid
     */
    public static function normalise_phone(string $phone): ?string
    {
        $digits = preg_replace('/\D/', '', $phone);
        if ($digits === '') {
            return '';
        }
        $digits = preg_replace('/^(?:00)?351/', '', $digits);

        return preg_match('/^9\d{8}$/', $digits) ? $digits : null;
    }

    /**
     * New payment expiry: extend a future expiry, otherwise count from now.
     *
     * @param int|null $expiry   current paymentData timestamp
     * @param string   $interval relative date, e.g. '+1 month'
     */
    public static function extended_payment_expiry(?int $expiry, string $interval, ?int $now = null): int
    {
        $now = $now ?? time();
        $base = $expiry !== null && $expiry > $now ? $expiry : $now;

        return (new DateTimeImmutable('@' . $base))->setTimezone(new DateTimeZone('UTC'))->modify($interval)->getTimestamp();
    }

    public static function valid_email(string $email): bool
    {
        return strlen($email) <= 254 && rcube_utils::check_email($email, false);
    }

    private function ldap(): sooma_gratuito_support_ldap
    {
        return $this->ldap ??= new sooma_gratuito_support_ldap();
    }

    /**
     * Find an account the current administrator may manage.
     *
     * @return array|null null when it doesn't exist or belongs to a domain the admin doesn't manage
     */
    private function find_managed_account(string $email): ?array
    {
        $account = $this->ldap()->find_account($email);
        if ($account === null) {
            return null;
        }

        $domain = substr($account['mail'], strrpos($account['mail'], '@') + 1);

        return $this->is_admin_for($domain) ? $account : null;
    }

    private function administrators(): array
    {
        return (array) $this->rc->config->get('sooma_gratuito_support_administrators', []);
    }

    private function is_admin(): bool
    {
        $user = strtolower((string) $this->rc->get_user_name());
        foreach ($this->administrators() as $admins) {
            if (in_array($user, array_map('strtolower', (array) $admins), true)) {
                return true;
            }
        }

        return false;
    }

    private function is_admin_for(string $domain): bool
    {
        $admins = $this->administrators()[strtolower($domain)] ?? [];

        return in_array(strtolower((string) $this->rc->get_user_name()), array_map('strtolower', (array) $admins), true);
    }

    private function assert_admin(): void
    {
        if (!$this->is_admin()) {
            rcube::raise_error(['code' => 403, 'message' => 'Not a support administrator'], false, true);
        }
    }

    private function posted_flag(): bool
    {
        return rcube_utils::get_input_string('_value', rcube_utils::INPUT_POST) === '1';
    }

    private function account_url(string $mail): string
    {
        return $this->rc->url(['_task' => 'support', '_action' => 'search', '_email' => $mail]);
    }

    /**
     * Store a message for the next page and redirect to the account page. Does not return.
     */
    private function redirect_to_account(string $mail, string $type, string $label, array $vars = []): void
    {
        $_SESSION[self::SESSION_NOTICE] = [$type, $this->gettext(['name' => $label, 'vars' => $vars])];
        $this->rc->output->redirect(
            $mail === ''
                ? ['_task' => 'support', '_action' => 'index']
                : ['_task' => 'support', '_action' => 'search', '_email' => $mail]
        );
    }

    private function audit(string $action, string $mail, string $outcome): void
    {
        rcube::write_log('sooma_gratuito_support', sprintf(
            '%s %s %s %s',
            $this->rc->get_user_name(),
            $action,
            $mail === '' ? '-' : $mail,
            $outcome
        ));
    }

    private function log_error(string $message): void
    {
        rcube::raise_error(['code' => 500, 'file' => __FILE__, 'line' => __LINE__,
            'message' => 'sooma_gratuito_support: ' . $message], true, false);
    }
}
