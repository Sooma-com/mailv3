<?php
declare(strict_types=1);
namespace Sooma\Smime;

class Compose
{
    private $plugin;

    public function __construct(\sooma_smime $plugin)
    {
        $this->plugin = $plugin;
        if ($this->plugin->rc->task == 'mail' && $this->plugin->rc->action == 'compose') {
            $this->add_labels();
            $this->plugin->api->add_content($this->content_compose_checkbox(), 'composeoptions');
        }
    }
    public function add_labels(): void {
        // $this->plugin->rc->output->add_label('select_import_file');
    }
    public function content_compose_checkbox(): string {
        $valid_certificates = count(DBCertificate::db_list($this->plugin, "owner = :owner AND email = :owner AND private_key IS NOT NULL AND not_before <= NOW() AND not_after >= NOW()", 1, ['owner' => $_SESSION['username']])['result']);
        if ($valid_certificates == 0) return '';
        ob_start();
?>
        <div class="form-group row form-check">
            <label for="compose-sooma-smime" class="col-form-label col-6"><?= $this->plugin->gettext('sign_message') ?></label>
            <div class="col-6 form-check">
                <input name="_sooma_smime_sign" id="compose-sooma-smime-sign" tabindex="2" class="form-check-input" value="1" type="checkbox" checked>
            </div>
        </div>
<?php
        return ob_get_clean();
    }
}
