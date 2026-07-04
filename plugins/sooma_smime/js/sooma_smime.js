(function() {
    const sooma_smime = {
        open_import_window: function() {
            const selected_certificate_id =  [ document.querySelector('tr.sooma_smime_certificate.selected') ]
                .filter( elm => elm !== null )
                .map( elm => elm.getAttribute('id') )
                .pop();

            const dialog_params = {
                _a: 'import',
                _framed: 1
            };
            if (selected_certificate_id) {
                dialog_params._certificate_id = selected_certificate_id;
            }
            var dialog = $('<iframe>').attr('src', rcmail.url('plugin.sooma_smime_import_cert_dialog', dialog_params)),
                import_func = function(dialog, e) {
                    var win = dialog[0].contentWindow;
                    this.import_cert(dialog);
                };

            this.cert_import_dialog = rcmail.simple_dialog(dialog, selected_certificate_id ? 'sooma_smime.importkeys' : 'sooma_smime.importcerts', import_func.bind(this, dialog), {
                button: selected_certificate_id ? rcmail.get_label('sooma_smime.importkeys') : rcmail.get_label('sooma_smime.importcerts'),
                width: 500,
                height: 180
            });
        },
        import_cert: function(dialog) {
            const gui = dialog[0].contentWindow.rcmail.gui_objects;
            const form = gui.cert_import_form;
            const id = 'certimport-' + new Date().getTime();
            const file = dialog[0].contentDocument.getElementById('sooma_smime_import_file');
            if (file && !file.value) {
                rcmail.alert_dialog(rcmail.get_label('sooma_smime.select_import_file'));
                return;
            }
            const lock = rcmail.set_busy(true, 'importwait');
            $('<iframe>').attr({name: id, style: 'display:none'}).appendTo(document.body);
            $(form).attr({target: id, action: rcmail.add_url(form.action, '_unlock', lock)}).submit();
            return true;
        },
        open_delete_window: function() {
            const row = document.querySelector('tr.sooma_smime_certificate.selected');
            if (!row) return;
            const certificate_id = row.getAttribute('id');
            if (!certificate_id) return;
            rcmail.confirm_dialog(rcmail.get_label('sooma_smime.cert_delete_msg'), 'delete', function(e, ref) {
                var lock = ref.display_message(ref.get_label('slime_smime.cert_delete_title'), 'loading');
                ref.http_post('plugin.sooma_smime_cert_delete', {'_id': certificate_id}, lock);
            });
        },
        // Accounts without a valid certificate still see the Certificado
        // (S/MIME) row's two controls (Compose.php always renders it now,
        // see that file's 2026-07-04 comment) - clicking either one here is
        // an upsell opportunity rather than a real toggle, since there's no
        // certificate/private key to actually sign or encrypt with.
        // Compose.php marks which checkboxes need this via the
        // ".smime-requires-certificate" class (only present when
        // data-has-certificate="0" on #compose-smime-row); accounts that
        // do have a certificate never get this class and behave normally.
        init_compose_upsell: function() {
            const row = document.getElementById('compose-smime-row');
            if (!row || row.dataset.hasCertificate === '1') return;
            row.querySelectorAll('input.smime-requires-certificate').forEach(function(input) {
                input.addEventListener('click', function(e) {
                    // Blocks the actual check/uncheck - nothing should look
                    // "on" for a feature the account can't use yet.
                    e.preventDefault();
                    sooma_smime.show_upsell();
                });
            });
        },
        // Placeholder message only - Manuel plans to design the real
        // upsell copy/flow (CTA, pricing link, etc.) separately; this just
        // wires the trigger point using the same rcmail.display_message()
        // pattern the rest of this plugin already uses for user feedback.
        show_upsell: function() {
            rcmail.display_message('Este recurso requer um certificado S/MIME ativo. Contacte-nos para o ativar.', 'notice');
        }
    };


    rcmail.addEventListener('init', function() {
        sooma_smime.gui = rcmail.gui_objects;
        sooma_smime.env = rcmail.env;
        if (sooma_smime.env.task == 'settings') {
            if (sooma_smime.env.action == 'plugin.sooma_smime_settings_section') {
                rcmail.register_command('plugin.sooma-cert-import', sooma_smime.open_import_window.bind(sooma_smime), true);
                rcmail.register_command('plugin.sooma-cert-delete', sooma_smime.open_delete_window.bind(sooma_smime), true);
            }
        }
        if (sooma_smime.env.task == 'mail' && sooma_smime.env.action == 'compose') {
            sooma_smime.init_compose_upsell();
        }
        if (sooma_smime.gui.mycertslist) {
            rcmail.mycertslist = new rcube_list_widget(sooma_smime.gui.mycertslist,
                {multiselect:false, draggable:false, keyboard:true});
            rcmail.mycertslist.init().focus();
        }
        if (sooma_smime.gui.othercertslist) {
            rcmail.othercertslist = new rcube_list_widget(sooma_smime.gui.othercertslist,
                {multiselect:false, draggable:false, keyboard:true});
            rcmail.othercertslist.init().focus();
        }
        if (sooma_smime.gui.mycertslist || sooma_smime.gui.othercertslist) {
            rcmail.sooma_smime_certs();
        }
    });

    rcube_webmail.prototype.sooma_smime_certs = function() {
        if (this.is_framed()) {
            return parent.rcmail.sooma_smime_certs();
        }
        if (this.mycertslist) {
            this.mycertslist.clear(true);
        }
        if (this.othercertslist) {
            this.othercertslist.clear(true);
        }
        if(!this.env.current_page){
            this.env.current_page = 1;
        }
        this.http_post('plugin.sooma_smime_cert_list', {'_page' : this.env.current_page}, this.set_busy(true, 'loading'));
    }
    rcube_webmail.prototype.sooma_smime_import_success = function() {
        const dialog = sooma_smime.cert_import_dialog;
        if (!dialog) return;
        dialog.dialog('destroy');
    }
    rcube_webmail.prototype.sooma_smime_update_cert_list = function(list, certificates, page_count) {
        if (list != 'mycerts' && list != 'othercerts') return;
        const list_widget = this[list + 'list'];
        list_widget.clear(true);
        const certificate_to_row = function(certificate) {
            var row = document.createElement('tr');
            var col = document.createElement('td');
            row.setAttribute('id', certificate.id);
            var class_name = "sooma_smime_certificate";
            class_name += (list == 'mycerts' ? ' sooma_smime_my_certificate' : ' sooma_smime_other_certificate');
            if (!certificate.private_key) {
                class_name += " sooma_smime_certificate_no_private_key";
            }
            row.setAttribute('class', class_name);
            row.addEventListener('click', function () {
                rcmail.sooma_smime_cert_select( row );
            });

            col.setAttribute('class', "sooma_smime_certificate_name");
            col.innerText = certificate.email + (certificate.private_key ? '' : ' ' + rcmail.get_label('sooma_smime.no_private_key'));
            row.appendChild(col);
            return row;
        };
        if (certificates.length > 0) {
            certificates.forEach(certificate => {
                list_widget.insert_row(certificate_to_row(certificate));
            });
        } else {
            var row = document.createElement('tr');
            var col = document.createElement('td');
            row.setAttribute('class', "sooma_smime_certificate_empty " + (list == 'mycerts' ? 'sooma_smime_my_certificate' : 'sooma_smime_other_certificate'));
            col.setAttribute('class', "sooma_smime_certificate_empty_message");
            col.innerText = rcmail.get_label('sooma_smime.no_certificates');
            row.appendChild(col);
            list_widget.insert_row(row);
        }
        list_widget.list.classList.remove('hidden');
        this.triggerEvent('listupdate', {list: list_widget, row_count: certificates.length});
        this.enable_command('plugin.sooma-cert-delete', false);
        this.enable_command('plugin.sooma-cert-import', true);
    }
    rcube_webmail.prototype.sooma_smime_cert_select = function(row) {
        document.querySelectorAll('tr.sooma_smime_certificate').forEach(element => { element.classList.remove('selected'); element.classList.remove('focused'); });
        row.classList.add('selected');
        row.classList.add('focused');
        this.enable_command('plugin.sooma-cert-delete', true);
        if (row.classList.contains('sooma_smime_certificate_no_private_key')) {
            this.enable_command('plugin.sooma-cert-import', true);
        } else {
            this.enable_command('plugin.sooma-cert-import', false);
        }
    }
})();