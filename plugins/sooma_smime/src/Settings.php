<?php
declare(strict_types=1);
namespace Sooma\Smime;

class Settings
{
    private $plugin;

    public function __construct(\sooma_smime $plugin)
    {
        $this->plugin = $plugin;
        if ($this->plugin->rc->task == 'settings') {
            $this->plugin->add_hook('settings_actions', [$this, 'settings_actions']);
            $this->plugin->register_action("plugin.sooma_smime_settings_section", [$this, 'settings_ui']);
            $this->plugin->rc->output->add_handlers([
                'mycertslist'     => [$this, 'object_mycertslist'],
                'othercertslist'     => [$this, 'object_othercertslist'],
                'countdisplay' => [$this, 'object_countdisplay'],
            ]);
            $this->plugin->register_action("plugin.sooma_smime_import_cert_dialog", [$this, 'action_import_cert_dialog']);
            $this->plugin->register_action("plugin.sooma_smime_cert_list", [$this, 'action_cert_list']);
            $this->plugin->register_action("plugin.sooma_smime_cert_delete", [$this, 'action_cert_delete']);
            $this->add_labels();
        }
    }
    public function add_labels(): void {
        $this->plugin->rc->output->add_label('select_import_file');
        $this->plugin->rc->output->add_label('no_certificates');
        $this->plugin->rc->output->add_label('no_private_key');
        $this->plugin->rc->output->add_label('cert_delete_msg');
        $this->plugin->rc->output->add_label('importcerts');
        $this->plugin->rc->output->add_label('importkeys');
    }

    public function settings_actions($args)
    {
        $args['actions'][] = [
            'type'   => 'link',
            'command' => 'plugin.sooma_smime_settings_section',
            'class'  => 'sooma_smime_section',
            'label'  => 'sooma_smime',
            'title'  => 'sooma_smime',
            'domain' => 'sooma_smime',
            'id'     => 'sooma_smime_section'
        ];
        return $args;
    }

    public function settings_ui()
    {
        $this->plugin->rc->output->set_pagetitle($this->plugin->gettext('sooma_smime'));
        $this->plugin->rc->output->send('sooma_smime.settings');
    }

    public function object_mycertslist($args)
    {
        $out = \rcmail_action::table_output($args, [], array('name'), 'id');
        $this->plugin->rc->output->add_gui_object('mycertslist', $args['id']);
        $this->plugin->rc->output->include_script('list.js');

        return $out;
    }

    public function object_othercertslist($args)
    {
        $out = \rcmail_action::table_output($args, [], array('name'), 'id');
        $this->plugin->rc->output->add_gui_object('othercertslist', $args['id']);
        $this->plugin->rc->output->include_script('list.js');

        return $out;
    }

    public function object_countdisplay($args)
    {
        $args['id'] = isset($args['id']) ? $args['id'] : 'soomaPageNum';
        $this->plugin->rc->output->add_gui_object('countdisplay', $args['id']);
        
        // $currentPage = $this->slime->settings->currentPageNumber;
        // $currentCertNum = isset($this->slime->settings->currentCertificatesNumber) ? $this->slime->settings->currentCertificatesNumber : 1;
        // $maxPage = $currentCertNum == 0 ? 1 : ceil($currentCertNum / $this->slime->settings->maxNumberOfCertificates);
        // TODO: Actually calculate this
        $currentPage = 1;
        $maxPage = 1;
        
        // makes values accessible in JS
        $this->plugin->rc->output->set_env('pagecount', $maxPage);
        $this->plugin->rc->output->set_env('current_page', $currentPage);
        
        $out = $this->plugin->gettext([
            'name' => 'page_num',
            'vars' => ['current_page' => $currentPage, 'max_page' => $maxPage]
        ]);

        return \html::span($args, $out);
    }

    public function action_import_cert_dialog()
    {
        if ($_SERVER['REQUEST_METHOD'] == 'POST') {
            return $this->action_import_cert_dialog_post();
        } else {
            return $this->action_import_cert_dialog_get();
        }
    }
    public function action_import_cert_dialog_post()
    {
        if (empty($_FILES['_file']) || empty($_FILES['_file']['tmp_name']) || !is_uploaded_file($_FILES['_file']['tmp_name'])) {
            header('HTTP/1.1 400 Bad Request');
            $this->plugin->rc->output->show_message($this->plugin->gettext('no_file_uploaded'), 'error');
            return $this->action_import_cert_dialog_get();
        }
        if (!empty($_FILES['_file']['error'])) {
            \rcmail_action::upload_error($_FILES['_file']['error']);
            $this->plugin->rc->output->send('iframe');
            return $this->action_import_cert_dialog_get();
        }
        if (isset($_REQUEST['_certificate_id'])) {
            header('Content-Type: text/plain');
            $certificate = DBCertificate::db_read($this->plugin, $_REQUEST['_certificate_id']);
            if ($certificate->owner !== $_SESSION['username']) {
                header('HTTP/1.1 403 Forbidden');
                $this->plugin->rc->output->show_message('You are not authorized to import this certificate', 'error');
                return;
            }
            $result = $certificate->import_key($this->plugin, $_FILES['_file']['tmp_name'], $_POST['_password']);
            if (is_string($result)) {
                $this->plugin->rc->output->show_message($result, 'error');
                return $this->action_import_cert_dialog_get();
            }
            $result->db_upsert($this->plugin);
        } else {
            $result = DBCertificate::import($this->plugin, $_FILES['_file']['tmp_name'], $_POST['_password']);
            if (is_string($result)) {
                $this->plugin->rc->output->show_message($result, 'error');
                return $this->action_import_cert_dialog_get();
            }
            $result->owner = $_SESSION['username'];
            $result->db_upsert($this->plugin);
        }
        $this->plugin->rc->output->show_message('sooma_smime.import_success', 'confirmation');
        $this->plugin->rc->output->command('parent.sooma_smime_certs');
        $this->plugin->rc->output->command('parent.sooma_smime_import_success');
    }
    public function action_import_cert_dialog_get()
    {
        $this->plugin->rc->output->add_handlers([
            'cert_import_form' => [$this, 'cert_import_form'],
        ]);
        $this->plugin->rc->output->set_pagetitle($this->plugin->gettext('sooma_smime'));
        $this->plugin->rc->output->send('sooma_smime.import_cert_dialog');
    }

    public function cert_import_form($args) {
        $args['id'] = 'CertImportForm';
        $form = [];
        if (isset($_REQUEST['_certificate_id'])) {
            $form[] = new \html_inputfield([
                'type'  => 'hidden',
                'name'  => '_certificate_id',
                'id'    => 'sooma_smime_import_certificate_id',
            ])->show($_REQUEST['_certificate_id']);
        }
        $form[] = new \html_inputfield([
            'type'  => 'file',
            'name'  => '_file',
            'id'    => 'sooma_smime_import_file',
            'size'  => 30,
            'class' => 'form-control'
        ])->show();
        $form[] = new \html_inputfield([
            'type'  => 'text',
            'name'  => '_password',
            'id'    => 'sooma_smime_import_password',
            'size'  => 30,
            'class' => 'form-control',
            'placeholder' => $this->plugin->gettext('password'),
        ])->show();
        $form = \html::div(null, implode(' ', $form));


        $this->plugin->rc->output->add_gui_object('cert_import_form', $args['id']);
        return $this->plugin->rc->output->form_tag([
            'action'  => $this->plugin->rc->url(['action' => $this->plugin->rc->action]),
            'method'  => 'post',
            'enctype' => 'multipart/form-data'
            ] + $args,
            $form
        );
    }
    public function action_cert_list()
    {
        $db_list = DBCertificate::db_list($this->plugin, "owner = :owner AND email = :owner ORDER BY id ASC", 1, ['owner' => $_SESSION['username']]);
        $certificates = $db_list['result'];
        $page_count = $db_list['pages'];
        unset($db_list);
        $this->plugin->rc->output->command('sooma_smime_update_cert_list', 'mycerts', array_map(
            function(DBCertificate $certificate) {
                $result =  json_decode(json_encode($certificate), true);
                $result['email'] = $certificate->certificate_email();
                $result['private_key'] = !is_null($certificate->private_key);
                return $result;
            },
            $certificates,
        ), $page_count);

        $db_list = DBCertificate::db_list($this->plugin, "owner = :owner AND email != :owner ORDER BY id ASC", 1, ['owner' => $_SESSION['username']]);
        $certificates = $db_list['result'];
        $page_count = $db_list['pages'];
        unset($db_list);
        $this->plugin->rc->output->command('sooma_smime_update_cert_list', 'othercerts', array_map(
            function(DBCertificate $certificate) {
                $result =  json_decode(json_encode($certificate), true);
                $result['email'] = $certificate->certificate_email();
                $result['private_key'] = !is_null($certificate->private_key);
                return $result;
            },
            $certificates,
        ), $page_count);
        $this->plugin->rc->output->send();
    }
    public function action_cert_delete()
    {
        if (!isset($_REQUEST['_id'])) {
            header('HTTP/1.1 400 Bad Request');
            $this->plugin->rc->output->show_message('No certificate ID provided', 'error');
            return;
        }
        try {
            $certificate = DBCertificate::db_read($this->plugin, $_REQUEST['_id']);
        } catch (DBException $e) {
            header('HTTP/1.1 404 Not Found');
            $this->plugin->rc->output->show_message('Certificate not found', 'error');
            return;
        }
        if ($certificate->owner !== $_SESSION['username']) {
            header('HTTP/1.1 403 Forbidden');
            $this->plugin->rc->output->show_message('You are not authorized to delete this certificate', 'error');
            return;
        }
        $certificate->db_delete($this->plugin);
        $this->plugin->rc->output->show_message('sooma_smime.cert_delete_success', 'confirmation');
        $this->plugin->rc->output->command('parent.sooma_smime_certs');
    }
}
