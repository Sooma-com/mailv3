<?php
require_once __DIR__ . '/lib/directory_driver.php';
require_once __DIR__ . '/lib/directory_driver_db.php';
require_once __DIR__ . '/lib/directory_driver_ldap.php';
require_once __DIR__ . '/lib/code_storage_driver.php';
require_once __DIR__ . '/lib/code_storage_driver_db.php';
require_once __DIR__ . '/lib/code_storage_driver_redis.php';
class reset_password extends rcube_plugin
{
    public $rc;
    public $_db = null;
    public $directory = null;
    public $recovery_codes = null;

    public function init()
    {
        $this->rc = rcmail::get_instance();
        if ($this->rc->task != 'login') return;
        $this->load_config();
        $this->add_texts('localization/');
        $this->include_script('js/reset_password.js');
        $this->add_hook('startup', [$this, 'startup']);
        $this->add_hook('render_page', [$this, 'add_labels']);
    }
    public function add_labels($args)
    {
        $this->rc->output->add_label('reset_password.forgot_password');
        $this->rc->output->add_label('reset_password.email');
        $this->rc->output->add_label('reset_password.email_placeholder');
        $this->rc->output->add_label('reset_password.recover_password');
        $this->rc->output->add_label('reset_password.confirm_recovery_email');
        $this->rc->output->add_label('reset_password.confirm_recovery_phone');
        $this->rc->output->add_label('reset_password.recovery_code');
        $this->rc->output->add_label('reset_password.password');
        $this->rc->output->add_label('reset_password.password_confirm');
        $this->rc->output->add_label('reset_password.change_password');
        $this->rc->output->add_label('reset_password.recovery_code_instructions');
        $this->rc->output->add_label('reset_password.password_restriction_confirmation');
        $this->rc->output->add_label('reset_password.password_restriction_length');
        $this->rc->output->add_label('reset_password.password_restriction_case');
        $this->rc->output->add_label('reset_password.password_restriction_digit');
        $this->rc->output->add_label('reset_password.password_restriction_nonalpha');
        $this->rc->output->add_label('reset_password.password_changed');
        $this->rc->output->add_label('reset_password.return_to_login');
    }
    public function startup($args) {
        switch ($this->rc->config->get('reset_password_directory_driver')) {
            case 'ldap':
                $this->directory = new reset_password_directory_ldap();
                break;
            case 'db':
                $this->directory = new reset_password_directory_db();
                break;
            default:
                if (!$this->rc->config->get('reset_password_directory_driver')) {
                    rcube::write_log('errors', 'reset_password: Directory driver not configured');
                } else {
                    rcube::write_log('errors', 'reset_password: Unknown reset_password_directory_driver "' . $this->rc->config->get('reset_password_directory_driver') . '"');
                }
                return;
        }
        switch ($this->rc->config->get('reset_password_code_storage_driver')) {
            case 'db':
                $this->recovery_codes = new reset_password_code_storage_driver_db();
                break;
            case 'redis':
                $this->recovery_codes = new reset_password_code_storage_driver_redis();
                break;
            default:
                if (!$this->rc->config->get('reset_password_code_storage_driver')) {
                    rcube::write_log('errors', 'reset_password: Code storage driver not configured');
                } else {
                    rcube::write_log('errors', 'reset_password: Unknown reset_password_code_storage_driver "' . $this->rc->config->get('reset_password_code_storage_driver') . '"');
                }
                return;
        }
        switch ($this->rc->action) {
            case 'plugin.password_recovery_start':
                $this->password_recovery_start($args);
                exit;
                break;
            case 'plugin.password_recovery_confirm_contact':
                $this->password_recovery_confirm_contact($args);
                exit;
                break;
            case 'plugin.password_recovery_change_password':
                $this->password_recovery_change_password($args);
                exit;
                break;
            case 'plugin.reset_password_custom_recovery_url':
                $this->custom_recovery_url($args);
                exit;
                break;
        }
    }
    public function custom_recovery_url($args) {
        $params = rcube_utils::request2param(rcube_utils::INPUT_POST);
        if (!$params['hostname']) $this->ajax_error('Hostname is required');
        $hostname = $params['hostname'];
        $hostname_custom_recovery_url_map = $this->rc->config->get('hostname_custom_recovery_url_map');
        if (isset($hostname_custom_recovery_url_map[$hostname])) {
            $this->rc->output->command('plugin.reset_password_redirect', [
                'url' => $url, 
            ]);
        } else {
            $this->rc->output->command('plugin.reset_password_show_recover_form');
        }
        $this->rc->output->send();
    }
    public function ajax_error($message) {
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => $message]);
        exit;
    }

    public function ajax_success($data) {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'data' => $data]);
        exit;
    }
    public function password_recovery_start($args) {
        $params = rcube_utils::request2param(rcube_utils::INPUT_POST);
        if (!isset($params['user'])) $this->ajax_error('User param is required');
        $user = explode('@', $params['user']);
        if (count($user) !== 2) $this->ajax_error('Invalid user format');
        $username = $user[0];
        $domain = $user[1];
        $email_domain_custom_recovery_url_map = $this->rc->config->get('email_domain_custom_recovery_url_map') ?? [];
        foreach ($email_domain_custom_recovery_url_map as $pattern => $url) {
            if ($pattern == $domain || @preg_match($pattern, $domain) === 1) {
                $this->ajax_success([
                    'custom_recovery_url' => $url,
                ]);
                return;
            }
        }
        list($recovery_email, $recovery_phone, $payment_active) = $this->directory->retrieve_recovery_contacts($username, $domain);
        if (!$recovery_email && !$recovery_phone) $this->ajax_error('Account does not exist or has no recovery contacts');
        $result = [
            'user' => $params['user'],
        ];
        if ($recovery_email) {
            $result['recovery_email_hint'] = $recovery_email;
            for ($i=2; $i < strlen($result['recovery_email_hint']) - 2; $i++) if (false === strpos(substr($result['recovery_email_hint'], $i-2, 5), "@")) $result['recovery_email_hint'][$i] = "*";
        }
        if ($recovery_phone) {
            $result['recovery_phone_hint'] = $recovery_phone;
            for ($i=1; $i < strlen($result['recovery_phone_hint']) - 2; $i++) $result['recovery_phone_hint'][$i] = "*";
        }
        $result['payment_active'] = $payment_active;
        $this->ajax_success($result);
    }
    public function password_recovery_confirm_contact($args) {
        $params = rcube_utils::request2param(rcube_utils::INPUT_POST);
        foreach (['user', 'recovery_email', 'recovery_phone'] as $key) if (!isset($params[$key])) $this->ajax_error(sprintf('%s param is required', $key));
        foreach (['recovery_email', 'recovery_phone'] as $key) if (empty($params[$key])) unset($params[$key]);
        if (!isset($params['recovery_email']) && !isset($params['recovery_phone'])) $this->ajax_error('At least one recovery contact is required');
        $user = explode('@', $params['user']);
        if (count($user) !== 2) $this->ajax_error('Invalid user format');
        $username = $user[0];
        $domain = $user[1];
        $email_domain_custom_recovery_url_map = $this->rc->config->get('email_domain_custom_recovery_url_map') ?? [];
        foreach ($email_domain_custom_recovery_url_map as $pattern => $url) {
            if ($pattern == $domain || @preg_match($pattern, $domain) === 1) {
                $this->ajax_success([
                    'custom_recovery_url' => $url,
                ]);
                return;
            }
        }
        list($recovery_email, $recovery_phone, $payment_active) = $this->directory->retrieve_recovery_contacts($username, $domain);
        if (!$recovery_email && !$recovery_phone) $this->ajax_error('Account does not exist or has no recovery contacts');
        if (isset($params['recovery_email']) && $params['recovery_email'] !== $recovery_email) $this->ajax_error('Invalid recovery email');
        if (isset($params['recovery_phone']) && $params['recovery_phone'] !== $recovery_phone) $this->ajax_error('Invalid recovery phone');
        if (!isset($params['recovery_email'])) $recovery_email = null;
        if (!isset($params['recovery_phone'])) $recovery_phone = null;
        $recovery_code = $this->recovery_codes->generate_recovery_code($username, $domain, [
            'email' => !is_null($recovery_email),
            'sms' => !is_null($recovery_phone),
        ]);
        if ($recovery_code['sent_count']['sms'] >= 2) $recovery_phone = null;
        if ($recovery_code['attempt_count'] > 100) $this->ajax_error('Too many attempts');
        $this->send_recovery_code($recovery_code['code'], $recovery_email, $recovery_phone, $params['user']);
        $this->ajax_success(['user' => $params['user']]);
    }
    protected function send_recovery_code($code, $recovery_email, $recovery_phone, $email) {
        $duo_config = $this->rc->config->get('reset_password_duo');
        if (!$duo_config) throw new Exception('Duo configuration not found');
        $duo_args = [
            'url' => sprintf('https://app.duo.pt/transactional/%d/message/%d/send?', $duo_config['transactional'], $duo_config['message']),
            'auth' => $duo_config['auth'],
        ];
        $url_args = [
            'code' => $code,
            'recovered_mail' => $email,
        ];
        if ($recovery_email) $url_args['email'] = $recovery_email;
        if ($recovery_phone) $url_args['telephone'] = $recovery_phone;
        $duo_args['url'] .= http_build_query($url_args);
        $ch = curl_init($duo_args['url']);
        curl_setopt($ch, CURLOPT_USERPWD, $duo_args['auth']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Accept: application/json',
        ]);
        $result = curl_exec($ch);
        curl_close($ch);
    }
    public function password_recovery_change_password($args) {
        $params = rcube_utils::request2param(rcube_utils::INPUT_POST);
        foreach (['user', 'code', 'password', 'password_confirm'] as $key) if (!isset($params[$key])) $this->ajax_error(sprintf('%s param is required', $key));
        $user = explode('@', $params['user']);
        if (count($user) !== 2) $this->ajax_error('Invalid user format');
        $username = $user[0];
        $domain = $user[1];
        $email_domain_custom_recovery_url_map = $this->rc->config->get('email_domain_custom_recovery_url_map') ?? [];
        foreach ($email_domain_custom_recovery_url_map as $pattern => $url) {
            if ($pattern == $domain || @preg_match($pattern, $domain) === 1) {
                $this->ajax_success([
                    'custom_recovery_url' => $url,
                ]);
                return;
            }
        }
        $recovery_code = $this->recovery_codes->generate_recovery_code($username, $domain, [
            'email' => false,
            'sms' => false,
        ]);
        if ($recovery_code['attempt_count'] > 100) $this->ajax_error('Too many attempts');
        if ($recovery_code['used']) $this->ajax_error('Recovery code already used');
        if ($recovery_code['code'] !== $params['code']) {
            $this->recovery_codes->increment_attempt_count($username, $domain);
            $this->ajax_error('Invalid recovery code');
            return;
        }
        if (!rcube::get_instance()->plugins->get_plugin('password')) {
            $this->ajax_error('Password plugin is not installed');
        }
        if ($params['password'] !== $params['password_confirm']) $this->ajax_error('Password and password confirmation do not match');
        // $this->directory->set_password($username, $domain, $params['password']);
        // The password plugin does not expose a save method. We'll basically reproduce 
        // its driver loading logic here, and then use the driver to change the password.
        $password_plugin_driver = rcube::get_instance()->config->get('password_driver', 'sql');
        $password_plugin_driver_file = RCUBE_PLUGINS_DIR . 'password/drivers/' . $password_plugin_driver . '.php';
        $password_plugin_driver_class = 'rcube_' . $password_plugin_driver . '_password';
        if (!file_exists($password_plugin_driver_file)) $this->ajax_error('Password plugin driver file not found');
        include_once $password_plugin_driver_file;
        rcube::get_instance()->plugins->get_plugin('password')->add_texts('../password/localization/');
        if (!class_exists($password_plugin_driver_class)) $this->ajax_error('Password plugin driver class not found');
        if (!method_exists($password_plugin_driver_class, 'save')) $this->ajax_error('Password plugin driver class does not have a save method');
        $password_plugin_driver_instance = new $password_plugin_driver_class();
        $password_plugin_driver_minimum_score = rcube::get_instance()->config->get('password_minimum_score');
        if (method_exists($password_plugin_driver_class, 'check_strength')) {
            if ($password_plugin_driver_instance->check_strength($params['password'])[0] < $password_plugin_driver_minimum_score) $this->ajax_error('Password is too weak');
        } else {
            if ($this->check_strength($params['password'])[0] < $password_plugin_driver_minimum_score) $this->ajax_error('Password is too weak');
        }
        $password_plugin_driver_instance->save($params['password'], $params['password_confirm'], $params['user']);
        $this->recovery_codes->mark_code_used($username, $domain, $params['code']);
        $this->ajax_success(true);
    }
    /**
    * Password strength check (used if password plugin does not have a check_strength method)
    *
    * @param string $passwd Password
    *
    * @return array Score (1 to 5) and Reason
    */
   protected function check_strength($passwd)
   {
       $rcmail = rcmail::get_instance();
       $score = 5;
       $reasons = [];
       if (strlen($passwd) < 8) {
           $score -= 2;
       }
       if (!preg_match('_[0-9]_', $passwd)) {
           $score -= 1;
           $reasons[] = $rcmail->gettext('password.mustcontaindigit');
       }
       if (!preg_match('_[a-z]_', $passwd) || !preg_match('_[A-Z]_', $passwd)) {
           $score -= 1;
           $reasons[] = $rcmail->gettext('password.mustcontainupperlower');
       }
       if (!preg_match('_[^0-9A-Za-z]_', $passwd)) {
           $score -= 1;
           $reasons[] = $rcmail->gettext('password.mustcontainnonalpha');
       }
       $reasons = implode("<br>", $reasons);
       if (!empty($reasons)) $reasons = "<br>" . $reasons;

       return [$score < 0 ? 0 : $score, $reasons];
   }
}
