<?php
declare(strict_types=1);
namespace Sooma\Smime;

class Signer {
    private $plugin;
    public function __construct(\sooma_smime $plugin)
    {
        $this->plugin = $plugin;
        if ($this->plugin->rc->task == 'mail') {
            $this->plugin->add_hook('message_before_send', [ $this, 'sign_message' ]);
        }
    }
    public function sign_message($args) {
        if (!isset($_REQUEST['_sooma_smime_sign']) || $_REQUEST['_sooma_smime_sign'] != '1') return $args;
        $valid_certificates = DBCertificate::db_list($this->plugin, "owner = :owner AND email = :owner AND private_key IS NOT NULL AND not_before <= NOW() AND not_after >= NOW()", 1, ['owner' => $_SESSION['username']])['result'];
        if (count($valid_certificates) == 0) return $args;
        $certificate = $valid_certificates[0];
        unset($valid_certificates);
        try {
            $args['message'] = $certificate->sign_message($args['message']);
        } catch (Exception $e) {
            $this->plugin->rc->output->command('display_message', 'Unable to sign message: ' . $e->getMessage(), 'error');
        }
        return $args;
    }
}