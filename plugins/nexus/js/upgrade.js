(function() {
    const updatePriceState = (form) => {
        const formData = new FormData(form);
        document.documentElement.queryElements("css:.nexus-price-options").forEach(priceOptions => {
            if (priceOptions.dataset.product !== formData.get('product')) {
                priceOptions.classList.add('hidden');
                priceOptions.queryElements("css:input[type='radio']").forEach(input => {
                    input.checked = false;
                });
            } else {
                priceOptions.classList.remove('hidden');
            }
        });
        const prices = 
        document
        .documentElement
        .queryElements("css:.nexus-price-options")
        .filter(priceOptions => priceOptions.dataset.product === formData.get('product'))
        .map(priceOptions => priceOptions.queryElements("xpath:./*"))
        .flat();
        if (0 == prices
            .map(price => price.queryElement("xpath:.//input"))
            .filter(input => input.checked)
            .length) {
            [
                prices
                .filter(price => price.classList.contains("yearly"))
                .pop()
            ].filter(price => price)
             .map(price => price.queryElement("xpath:.//input"))
             .forEach(input => input.checked = true);
        }
        document.getElementById("nexus-price-selector").classList.remove("hidden");
        document.documentElement
        .queryElements("css:#nexus-price-selector:not(:has(.nexus-price-options:not(.hidden))")
        .forEach(priceSelector => {
            priceSelector.classList.add("hidden");
        });
    }
    const updateCustomerInfoState = (form) => {
        const formData = new FormData(form);
        const customerInfo = document.getElementById('nexus-customer-info');
        if (!customerInfo) return;
        if (formData.get("product") && formData.get("price")) {
            customerInfo.classList.remove('hidden');
        } else {
            customerInfo.classList.add('hidden');
        }
    }
    const updatePaymentMethodState = (form) => {
        const formData = new FormData(form);
        const paymentMethod = document.getElementById('nexus-payment-method');
        if (!paymentMethod) return;
        const price = formData.get("price");
        if (price) {
            paymentMethod.queryElements("css:label:has(input[type='radio'])").forEach(label => {
                if (label.classList.contains(price)) {
                    label.classList.remove('hidden');
                } else {
                    label.classList.add('hidden');
                }
            });
        }
        if (formData.get("payment_method") && formData.get("payment_method") == "mbway") {
            [ document.getElementById("mbway-data") ].filter(element => element).forEach(element => element.classList.remove('hidden'));
        } else {
            [ document.getElementById("mbway-data") ].filter(element => element).forEach(element => element.classList.add('hidden'));
        }
        if (!formData.get("product")
            || !formData.get("price")
            || Array.from(form.elements)
                    .filter(element => element.name == "customer_vat_id" || element.name == "customer_name")
                    .find(element => !element.validity.valid)) {
            paymentMethod.classList.add("hidden");
        } else {
            paymentMethod.classList.remove("hidden");
        }
    }
    const updateFormActiveStage = (form) => {
        const stageIds = [
            "nexus-product-selector",
            "nexus-price-selector",
            "nexus-customer-info",
            "nexus-payment-method",
        ];
        const firstHiddenStage = stageIds.find(stageId => document.getElementById(stageId).classList.contains("hidden"));
        const activeStage = stageIds[ stageIds.indexOf(firstHiddenStage) != -1 ? stageIds.indexOf(firstHiddenStage) - 1 : stageIds.length -1 ];
        stageIds.forEach(stageId => {
            document.getElementById(stageId).classList.remove("active");
        });
        document.getElementById(activeStage).classList.add("active");
        {
            const formData = new FormData(form);
            if (typeof formData.get("product") === "string" && formData.get("product").length == 0) {
                console.log("here");
                exit;
                form.submit();
            }
        }
        if (activeStage == "nexus-payment-method") {
            const paymentMethod = new FormData(form).get("payment_method");
            if (paymentMethod && paymentMethod != "mbway") {
                form.submit();
            }
        }
    }
    const updateFormState = (form) => {
        updatePriceState(form);
        updateCustomerInfoState(form);
        updatePaymentMethodState(form);
        updateFormActiveStage(form);
    };
    const setupFormStateUpdate = () => {
        const form = document.getElementById('upgrade-form');
        if (!form) return;
        form.addEventListener('change', updateFormState.bind(null, form));
        form.addEventListener('keydown', (ev) => {
            if (ev.key == "Enter") {
                ev.preventDefault();
                ev.stopPropagation();
            }
        });
    }
    const isVATIDValid = (vatID, countryCode) => {
        if (countryCode != "PT") {
            console.error("Only Portuguese VAT IDs are supported");
            return true; // Only Portuguese VAT IDs are supported, so 
        }
        if (matches = /^(?:PT)?([0-9]{9})$/.exec(vatID)) {
            const vat_digits = matches[1];
            const multipliers = [9, 8, 7, 6, 5, 4, 3, 2];
            let check_digit = 0;
            for (let i = 0; i < 8; i++) {
                check_digit += Number(vat_digits.charAt(i)) * multipliers[i];
            }
            check_digit = 11 - (check_digit % 11);
            if (check_digit > 9) check_digit = 0;
            return check_digit == Number(vat_digits.charAt(8));
        } else {
            return false;
        }
    }
    const setupVatValidation = () => {
        const form = document.getElementById('upgrade-form');
        if (!form) return;
        const vatInput = form.queryElement("xpath:.//input[@name='customer_vat_id']");
        if (!vatInput) return;
        vatInput.addEventListener('change', (ev) => {
            ev.target.value = ev.target.value.replace(/\s/g, '');
            ev.target.setCustomValidity("");
            if (/^[0-9]{9}$/.test(ev.target.value)) {
                ev.target.value = "PT" + ev.target.value;
            }
            const errorSpan = vatInput.queryElement("xpath:../span[contains(concat(' ',normalize-space(@class),' '),' form-error ')]");
            if (!errorSpan) return;
            errorSpan.textContent = "";
            if (!/^[A-Z]{2}[0-9]{9}$/.test(ev.target.value)) {
                errorSpan.textContent = rcmail.gettext("nexus.vat_invalid");
                ev.target.setCustomValidity(rcmail.gettext("nexus.vat_invalid"));
                return;
            }
            if (!/^PT[0-9]{9}$/.test(ev.target.value)) {
                errorSpan.textContent = rcmail.gettext("nexus.vat_non_portuguese");
                ev.target.setCustomValidity(rcmail.gettext("nexus.vat_non_portuguese"));
                return;
            }
            if (!isVATIDValid(ev.target.value, "PT")) {
                errorSpan.textContent = rcmail.gettext("nexus.vat_invalid");
                ev.target.setCustomValidity(rcmail.gettext("nexus.vat_invalid"));
                return;
            }
            if (matches = /^PT([0-9]{3})([0-9]{3})([0-9]{3})$/.exec(ev.target.value)) {
                ev.target.value = "PT" + matches[1] + " " + matches[2] + " " + matches[3];
            }
        });
    }
    const setupCustomerNameValidation = () => {
        const form = document.getElementById('upgrade-form');
        if (!form) return;
        const nameInput = form.queryElement("xpath:.//input[@name='customer_name']");
        if (!nameInput) return;
        const errorSpan = nameInput.queryElement("xpath:../span[contains(concat(' ',normalize-space(@class),' '),' form-error ')]");
        if (!errorSpan) return;
        nameInput.addEventListener('input', (ev) => {
            errorSpan.textContent = "";
            ev.target.setCustomValidity("");
            if (ev.target.value.length == 0) {
                errorSpan.textContent = rcmail.gettext("nexus.customer_name_required");
                ev.target.setCustomValidity(rcmail.gettext("nexus.customer_name_required"));
            }
            updateFormState(form);
        });
        nameInput.addEventListener('change', (ev) => {
            ev.target.value = ev.target.value.trim();
            errorSpan.textContent = "";
            ev.target.setCustomValidity("");
            if (ev.target.value.length == 0) {
                errorSpan.textContent = rcmail.gettext("nexus.customer_name_required");
                ev.target.setCustomValidity(rcmail.gettext("nexus.customer_name_required"));
            }
            updateFormState(form);
        });
    }
    const setupFormErrorHiddenClass = () => {
        const handler = (ev) => {
            const textContent = ev[0].target.textContent.trim();
            if (textContent.length == 0) {
                ev[0].target.classList.add('hidden');
            } else {
                ev[0].target.classList.remove('hidden');
            }
        }
        document.documentElement.queryElements("css:span.form-error").forEach(errorSpan => {
            handler([{target: errorSpan}]);
            (new MutationObserver(handler)).observe(errorSpan, { attributes: false, childList: true, subtree: true });

        });
    }
    const setupMBWayValidation = () => {
        const form = document.getElementById('upgrade-form');
        if (!form) return;
        const mbwayInput = form.queryElement("xpath:.//input[@name='mbway_telephone']");
        if (!mbwayInput) return;
        mbwayInput.addEventListener('change', (ev) => {
            const value = ev.target.value.replace(/\s/g, '');
            ev.target.setCustomValidity("");
            if (!/^9[123][0-9]{7}$/.test(ev.target.value)) {
                ev.target.setCustomValidity(rcmail.gettext("nexus.invalid_cellphone"));
                return;
            }
            ev.target.value = value;
        });
    }
    window.addEventListener('load', () => {
        setupFormErrorHiddenClass();
        setupVatValidation();
        setupCustomerNameValidation();
        setupFormStateUpdate();
        setupMBWayValidation();
        updateFormState(document.getElementById('upgrade-form'));
    });
})();
