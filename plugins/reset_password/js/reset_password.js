window.sooma_reset_password = {
    init: function () {
        rcmail.addEventListener('init', function () {
            if (rcmail.env.task !== 'login') return;
            this.add_link_to_login_form();
        }.bind(this));
    },
    displayError: function (message) {
        const messageStack = (function () {
            const existing = document.getElementById('message-stack');
            if (existing) return existing;
            const div = document.createElement('div');
            div.setAttribute('id', 'messagestack');
            document.body.appendChild(div);
            return div;
        })();
        messageStack.appendChild((function () {
            const div = document.createElement('div');
            div.setAttribute('class', 'error content');
            div.setAttribute('role', 'alert');
            div.textContent = message;
            return div;
        })());
    },
    add_link_to_login_form: function () {
        const loginForm = document.getElementById('login-form');
        loginForm.appendChild((function () {
            const link = document.createElement('a');
            link.setAttribute('href', '#');
            link.setAttribute('class', 'forgot-password-link');
            link.textContent = rcmail.gettext('forgot_password', 'reset_password');
            link.addEventListener('click', this.handleForgotPasswordClick.bind(this));
            return link;
        }).bind(this)());
    },
    handleForgotPasswordClick: function (event) {
        if (window.location.hostname == "webmail.oa.pt") {
            window.location = "https://portal.oa.pt/reporpass";
            if (event) {
                event.preventDefault();
                event.stopPropagation();
            }
            return;
        }
        const loginForm = document.getElementById('login-form');
        if (!loginForm) return;
        loginForm.replaceWith((function () {
            const form = document.createElement('form');
            form.setAttribute('id', 'login-form');
            form.setAttribute('method', 'post');
            form.setAttribute('action', '/');
            form.setAttribute('class', 'propform recover-password-form');
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_task');
                input.setAttribute('value', 'login');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_action');
                input.setAttribute('value', 'plugin.password_recovery_start');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const label = document.createElement('label');
                label.setAttribute('for', '_user');
                label.textContent = rcmail.gettext('email', 'reset_password');
                return label;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'email');
                input.setAttribute('name', '_user');
                input.setAttribute('required', 'required');
                input.setAttribute('placeholder', rcmail.gettext('email_placeholder', 'reset_password'));
                input.setAttribute('class', 'form-control');
                input.setAttribute('autocomplete', 'email');
                input.setAttribute('size', '40');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const p = document.createElement('p');
                p.setAttribute('class', 'formbuttons');
                const button = p.appendChild(document.createElement('button'));
                button.setAttribute('type', 'submit');
                button.setAttribute('class', 'button mainaction submit');
                button.textContent = rcmail.gettext('recover_password', 'reset_password');
                return p;
            }).bind(this)());
            form.addEventListener('submit', this.handleRecoverPasswordSubmit.bind(this));
            return form;
        }).bind(this)());
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
    },
    ajaxFormSubmit: async function (form) {
        try {
            const formData = new FormData(form);
            const response = await fetch(form.action, { method: 'POST', body: formData });
            if (response.ok) {
                payload = await response.json();
                if (!payload.success) {
                    this.displayError(payload.message);
                    return false;
                }
                return payload.data;
            } else {
                console.error('Password recovery request failed:', response.statusText);
                this.displayError('Password recovery request failed: ' + response.statusText);
                return false;
            }
        } catch (error) {
            console.error('Network error:', error);
            this.displayError('Network error: ' + error.message);
            return false;
        }
    },
    handleRecoverPasswordSubmit: async function (event) {
        event.preventDefault();
        event.stopPropagation();
        const payload = await this.ajaxFormSubmit(event.target);
        if (!payload) return;
        const loginForm = document.getElementById('login-form');
        if (!loginForm) return;
        loginForm.replaceWith((function () {
            const form = document.createElement('form');
            form.setAttribute('id', 'login-form');
            form.setAttribute('method', 'post');
            form.setAttribute('action', '/');
            form.setAttribute('class', 'propform recover-password-form');
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_task');
                input.setAttribute('value', 'login');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_action');
                input.setAttribute('value', 'plugin.password_recovery_confirm_contact');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_user');
                input.setAttribute('value', payload.user);
                return input;
            }).bind(this)());
            if (payload.recovery_email_hint) {
                form.appendChild((function () {
                    const label = document.createElement('label');
                    label.setAttribute('for', '_recovery_email');
                    label.textContent = rcmail.gettext('confirm_recovery_email', 'reset_password');
                    return label;
                }).bind(this)());
                form.appendChild((function () {
                    const input = document.createElement('input');
                    input.setAttribute('type', 'email');
                    input.setAttribute('name', '_recovery_email');
                    input.setAttribute('placeholder', payload.recovery_email_hint);
                    input.setAttribute('class', 'form-control');
                    input.setAttribute('size', '40');
                    return input;
                }).bind(this)());
            }
            if (payload.recovery_phone_hint) {
                form.appendChild((function () {
                    const label = document.createElement('label');
                    label.setAttribute('for', '_recovery_phone');
                    label.textContent = rcmail.gettext('confirm_recovery_phone', 'reset_password');
                    return label;
                }).bind(this)());
                form.appendChild((function () {
                    const input = document.createElement('input');
                    input.setAttribute('type', 'text');
                    input.setAttribute('name', '_recovery_phone');
                    input.setAttribute('placeholder', payload.recovery_phone_hint);
                    input.setAttribute('class', 'form-control');
                    input.setAttribute('size', '40');
                    return input;
                }).bind(this)());
            }
            form.appendChild((function () {
                const p = document.createElement('p');
                p.setAttribute('class', 'formbuttons');
                const button = p.appendChild(document.createElement('button'));
                button.setAttribute('type', 'submit');
                button.setAttribute('class', 'button mainaction submit');
                button.textContent = rcmail.gettext('recover_password', 'reset_password');
                return p;
            }).bind(this)());
            form.addEventListener('submit', this.handleRecoverPasswordConfirmContactSubmit.bind(this));
            return form;
        }).bind(this)());
    },
    handleRecoverPasswordConfirmContactSubmit: async function (event) {
        event.preventDefault();
        event.stopPropagation();
        const payload = await this.ajaxFormSubmit(event.target);
        if (!payload) return;
        const loginForm = document.getElementById('login-form');
        if (!loginForm) return;
        loginForm.replaceWith((function () {
            const form = document.createElement('form');
            form.setAttribute('id', 'login-form');
            form.setAttribute('method', 'post');
            form.setAttribute('action', '/');
            form.setAttribute('class', 'propform recover-password-form');
            form.appendChild((function () {
                const div = document.createElement('div');
                div.setAttribute('class', 'form-instructions');
                div.textContent = rcmail.gettext('recovery_code_instructions', 'reset_password');
                return div;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_task');
                input.setAttribute('value', 'login');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_action');
                input.setAttribute('value', 'plugin.password_recovery_change_password');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'hidden');
                input.setAttribute('name', '_user');
                input.setAttribute('value', payload.user);
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const label = document.createElement('label');
                label.setAttribute('for', '_code');
                label.textContent = rcmail.gettext('recovery_code', 'reset_password');
                return label;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'text');
                input.setAttribute('name', '_code');
                input.setAttribute('placeholder', '123456');
                input.setAttribute('required', 'required');
                input.setAttribute('class', 'form-control');
                input.setAttribute('size', '40');
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const label = document.createElement('label');
                label.setAttribute('for', '_password');
                label.textContent = rcmail.gettext('password', 'reset_password');
                return label;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'password');
                input.setAttribute('name', '_password');
                input.setAttribute('class', 'form-control');
                input.setAttribute('size', '40');
                input.addEventListener('input', this.validatePassword.bind(this));
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const label = document.createElement('label');
                label.setAttribute('for', '_password_confirm');
                label.textContent = rcmail.gettext('password_confirm', 'reset_password');
                return label;
            }).bind(this)());
            form.appendChild((function () {
                const input = document.createElement('input');
                input.setAttribute('type', 'password');
                input.setAttribute('name', '_password_confirm');
                input.setAttribute('class', 'form-control');
                input.setAttribute('size', '40');
                input.addEventListener('input', this.validatePassword.bind(this));
                return input;
            }).bind(this)());
            form.appendChild((function () {
                const p = document.createElement('p');
                p.setAttribute('class', 'formbuttons');
                const button = p.appendChild(document.createElement('button'));
                button.setAttribute('type', 'submit');
                button.setAttribute('class', 'button mainaction submit');
                button.textContent = rcmail.gettext('change_password', 'reset_password');
                return p;
            }).bind(this)());
            form.appendChild((function () {
                const ul = document.createElement('ul');
                ul.setAttribute('id', 'password-restrictions');
                [
                    'password_restriction_confirmation',
                    'password_restriction_length',
                    'password_restriction_case',
                    'password_restriction_digit',
                    'password_restriction_nonalpha'
                ].forEach(function (restriction) {
                    ul.appendChild((function () {
                        const li = document.createElement('li');
                        li.setAttribute('id', restriction);
                        li.textContent = rcmail.gettext(restriction, 'reset_password');
                        return li;
                    }).bind(this)());
                });

                return ul;
            }).bind(this)());
            form.addEventListener('submit', this.handleChangePasswordSubmit.bind(this));
            return form;
        }).bind(this)());
    },

    validatePassword: function () {
        const form = document.getElementById('login-form');
        if (!form) return;
        const password = form.elements['_password'].value;
        const passwordConfirm = form.elements['_password_confirm'].value;
        var failScore = 0;
        if (password == passwordConfirm) {
            document.getElementById('password_restriction_confirmation').classList.add('valid');
        } else {
            document.getElementById('password_restriction_confirmation').classList.remove('valid');
            failScore += 2;
        }
        if (password.length >= 8) {
            document.getElementById('password_restriction_length').classList.add('valid');
        } else {
            document.getElementById('password_restriction_length').classList.remove('valid');
            failScore += 2;
        }
        if (password.match(/[A-Z]/) && password.match(/[a-z]/)) {
            document.getElementById('password_restriction_case').classList.add('valid');
        } else {
            document.getElementById('password_restriction_case').classList.remove('valid');
            failScore += 1;
        }
        if (password.match(/[0-9]/)) {
            document.getElementById('password_restriction_digit').classList.add('valid');
        } else {
            document.getElementById('password_restriction_digit').classList.remove('valid');
            failScore += 1;
        }
        if (password.match(/[^a-zA-Z0-9]/)) {
            document.getElementById('password_restriction_nonalpha').classList.add('valid');
        } else {
            document.getElementById('password_restriction_nonalpha').classList.remove('valid');
            failScore += 1;
        }
        form.queryElements('css:button.submit').forEach(function (button) {
            if (failScore > 1) {
                button.setAttribute('disabled', 'disabled');
            } else {
                button.removeAttribute('disabled');
            }
        });
    },
    handleChangePasswordSubmit: async function (event) {
        event.preventDefault();
        event.stopPropagation();
        const payload = await this.ajaxFormSubmit(event.target);
        if (!payload) return;
        const loginForm = document.getElementById('login-form');
        if (!loginForm) return;
        loginForm.replaceWith((function () {
            const form = document.createElement('form');
            form.setAttribute('id', 'login-form');
            form.setAttribute('method', 'GET');
            form.setAttribute('action', '/');
            form.setAttribute('class', 'propform recover-password-form');
            form.appendChild((function () {
                const div = document.createElement('div');
                div.setAttribute('class', 'form-instructions');
                div.textContent = rcmail.gettext('password_changed', 'reset_password');
                return div;
            }).bind(this)());
            form.appendChild((function () {
                const p = document.createElement('p');
                p.setAttribute('class', 'formbuttons');
                const button = p.appendChild(document.createElement('button'));
                button.setAttribute('type', 'submit');
                button.setAttribute('class', 'button mainaction submit');
                button.textContent = rcmail.gettext('return_to_login', 'reset_password');
                return p;
            }).bind(this)());
            return form;
        }).bind(this)());
    },
};
(function (f) {
    if (document.readyState !== 'complete') { f(); } else { window.addEventListener('load', f); }
})(window.sooma_reset_password.init.bind(window.sooma_reset_password));
