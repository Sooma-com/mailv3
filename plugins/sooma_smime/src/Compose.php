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
        $has_certificate = $valid_certificates > 0;
        ob_start();
?>
        <!--
            Restyled to match the compose sidebar's shared "row label + a
            few pill-toggles" pattern (.toggle-group/.toggle-item, see the
            skin's widgets/_toggle-group.scss - same one the Recibos row
            uses), instead of a single bare checkbox, now that there are
            two related options to show side by side (Manuel, 2026-07-04).

            Row used to return '' entirely for accounts with no valid
            certificate, so non-subscribers never saw S/MIME existed at
            all. Manuel wants it the other way round: always show the row,
            and use it as an upsell surface - accounts without a
            certificate see the same two controls, but clicking either one
            shows an upsell message instead of actually turning anything on
            (js/sooma_smime.js's init_compose_upsell(), keyed off this row's
            data-has-certificate attribute) (Manuel, 2026-07-04).

            "Encriptar" stays disabled/dimmed (.toggle-item-disabled) only
            for accounts that already *have* a certificate - that's a real,
            separate feature gap (the plugin has no encryption
            implementation yet, only signing, see Signer.php), not a sales
            gate. For accounts with no certificate, Encriptar is part of
            the upsell instead, so it renders like a normal, inviting
            control alongside Assinar rather than looking broken/disabled.
        -->
        <div class="form-group row form-check" id="compose-smime-row" data-has-certificate="<?= $has_certificate ? '1' : '0' ?>">
            <!--
                Same .help-tip widget as Recibos - "Assinar"/"Encriptar" are
                jargon (S/MIME signing vs. encryption) that a lawyer using
                this compose sidebar for the first time has no reason to
                already know, same rationale as the Recibos row's own tip
                (Manuel, 2026-07-04).

                "digital" and the icon are wrapped together in
                .help-tip-nowrap (widgets/_help-tip.scss) rather than just
                separated by a &nbsp; - a trailing non-breaking space alone
                wasn't enough to stop the "?" landing alone on its own line
                below "Certificado digital" in this narrow column; see that
                widget's comment for why (Manuel, 2026-07-04).
            -->
            <label for="compose-sooma-smime-sign" class="col-form-label col-6">Certificado <span class="help-tip-nowrap">digital <span class="help-tip" tabindex="0">
                    <span class="help-tip-icon" aria-hidden="true">?</span>
                    <span class="help-tip-bubble" role="tooltip"><strong>Assinar</strong> - aplica uma assinatura digital S/MIME que garante a autenticidade do remetente e a integridade da mensagem.<br /><strong>Encriptar</strong> - cifra o conteúdo da mensagem, garantindo que só o destinatário a consegue ler.</span>
                </span></span></label>
            <div class="col-6 toggle-group">
                <div class="toggle-item">
                    <span class="toggle-item-label">Assinar</span>
                    <input name="_sooma_smime_sign" id="compose-sooma-smime-sign" tabindex="2" class="form-check-input<?= $has_certificate ? '' : ' smime-requires-certificate' ?>" value="1" type="checkbox" <?= $has_certificate ? 'checked' : '' ?>>
                </div>
                <div class="toggle-item<?= $has_certificate ? ' toggle-item-disabled' : '' ?>"<?= $has_certificate ? ' title="Brevemente disponível"' : '' ?>>
                    <span class="toggle-item-label">Encriptar</span>
                    <input id="compose-sooma-smime-encrypt" tabindex="<?= $has_certificate ? '-1' : '2' ?>" class="form-check-input<?= $has_certificate ? '' : ' smime-requires-certificate' ?>" value="1" type="checkbox" <?= $has_certificate ? 'disabled' : '' ?>>
                </div>
            </div>
        </div>
<?php
        return ob_get_clean();
    }
}
