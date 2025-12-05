window.sergiosgc.callOnLoad(function () {
    class RecipientInput {
        constructor(element) {
            this.topElement = document.createElement("div");
            this.topElement.classList.add("recipient-input");
            element.parentNode.replaceChild(this.topElement, element);
            this.userInput = this.topElement.appendChild((function () {
                const input = document.createElement("input");
                input.recipientInput = this;
                input.setAttribute("type", "text");
                input.value = element.value;
                return input;
            }).bind(this)());

            this.topElement.appendChild(element);
            this.submittedInput = element;
            this.parseRecipients();
            this.userInput.addEventListener("keyup", this.onKeyUp.bind(this));
            this.topElement.addEventListener("click", this.onRecipientClick.bind(this));
            this.userInput.form.addEventListener("submit", this.onSubmit.bind(this));
            this.userInput.addEventListener("change", this.parseRecipients.bind(this));
        }
        onSubmit() {
            this.parseRecipients();
            const non_parsed_recipient = this.userInput.value.trim();
            this.submittedInput.value = [
                this.submittedInput.value,
                non_parsed_recipient
            ].filter(s => s.trim().length).join(", ");
        }
        onKeyUp(event) {
            if (event.key === "," || event.key === ";" || event.key === "Enter") this.parseRecipients();
            if (event.key === "Enter") event.preventDefault();
            if (event.key === "Backspace" && this.userInput.selectionStart === 0 && this.userInput.selectionEnd === 0) {
                const lastRecipient = this.topElement.queryElements("css:.recipient-input-recipient").pop();
                if (lastRecipient) {
                    const removedRecipient = this.removeRecipient(lastRecipient);
                    this.userInput.value = [
                        removedRecipient,
                        this.userInput.value
                    ].filter(s => s.trim().length).join(", ");
                    this.userInput.setSelectionRange(removedRecipient.length, removedRecipient.length);
                }
            }
        }
        onRecipientClick(event) {
            if (!event.target.classList.contains("recipient-input-recipient")) return;
            this.removeRecipient(event.target);
        }
        removeRecipient(recipient) {
            if (typeof recipient === "string") {
                this.topElement
                    .queryElements("css:.recipient-input-recipient .recipient-input-recipient-email")
                    .filter(element => element.textContent === recipient)
                    .map(element => element.parentNode)
                    .forEach(this.removeRecipient.bind(this))

                return;
            }
            const result = this.recipientInputToText(recipient);
            recipient.remove();
            this.updateSubmittedInput();
            return result;
        }
        updateSubmittedInput() {
            this.submittedInput.value = this.topElement
                .queryElements("css:.recipient-input-recipient")
                .map(this.recipientInputToText.bind(this))
                .join(", ");
        }
        recipientInputToText(recipient) {
            const name = recipient.queryElement("css:.recipient-input-recipient-name").textContent.trim();
            const email = recipient.queryElement("css:.recipient-input-recipient-email").textContent.trim();
            if (name) {
                if (/[^a-zA-Z0-9]/g.test(name)) {
                    return `${name} <${email}>`;
                }
                const quotedName = name.replace("\"", "\\\"");
                return `"${quotedName}" <${email}>`;
            }
            return email;
        }
        parseRecipients() {
            const text = this.userInput.value.replace(/[,;\s]*[\r\n]+/g, ',').trim();
            var address_regex = /^(?:(?:^"(?<quoted_name>(?:[^"]|\")*)")|(?<unquoted_name>[^<]*?))\s*(?:<(?<quoted_email>[^>@]+@[^>.]+\.[^>]+)>|(?<unquoted_email>[^<>@]+@[^.]+\..+))$/,
                global_rx = /(?=\S)[^",;]*(?:"[^\\"]*(?:\\[,;\S][^\\"]*)*"[^",;]*)*/g,
                matches = (text.match(global_rx) || []).map(match => match.trim());
            this.userInput.value = matches
                .filter(match => !address_regex.test(match))
                .filter(match => match.length)
                .join(", ");
            matches
                .filter(match => address_regex.test(match))
                .map(match => address_regex.exec(match))
                .map(match => {
                    return {
                        name: match.groups.quoted_name || match.groups.unquoted_name,
                        email: match.groups.quoted_email || match.groups.unquoted_email
                    }
                })
                .forEach(recipient => this.insertRecipient.bind(this)(recipient));
            this.updateSubmittedInput();
        }
        insertRecipient(recipient) {
            let referenceElement = this.topElement.firstChild;
            while (referenceElement.classList.contains("recipient-input-recipient")) referenceElement = referenceElement.nextSibling;
            referenceElement.parentNode.insertBefore((function () {
                const span = document.createElement("span");
                span.classList.add("recipient-input-recipient");
                if (recipient.name.trim().length) {
                    span.classList.add("recipient-input-recipient-name-present");
                }
                const name = span.appendChild(document.createElement("span"));
                name.classList.add("recipient-input-recipient-name");
                name.textContent = recipient.name;
                const email = span.appendChild(document.createElement("span"));
                email.classList.add("recipient-input-recipient-email");
                email.textContent = recipient.email;
                return span;
            })(), referenceElement);
        }
    };
    document.documentElement.queryElements("css:*[data-recipient-input]").forEach(function (element) {
        new RecipientInput(element);
    });
});