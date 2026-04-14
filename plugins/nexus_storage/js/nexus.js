(function() {
    const linkSoomaProfileDialogQuotaLabel = () => {
        const handlerFunction = (ev) => {
            if (ev.detail.target.queryElement("xpath:./a")) return;
            const link = document.createElement("a");
            link.setAttribute("href", rcmail.url("mail/plugin.nexus_storage_upgrade"));
            link.textContent = ev.detail.target.textContent;
            while (ev.detail.target.firstChild) {
                ev.detail.target.firstChild.remove();
            }
            ev.detail.target.appendChild(link);
        };

        (new sergiosgc.XPathObserver("//*[@id='sooma-profile-dialog-quota-label']"))
            .addEventListener("xpathobserver.node.new", handlerFunction);
    };

    const addUpgradeButton = () => {
        const xpath = "//*[@id='sooma-profile-dialog']/*[contains(concat(' ',normalize-space(@class),' '),' sooma-profile-dialog-row-1 ')]";
        const handlerFunction = (ev) => {
            const targetRow = document.documentElement.queryElement("xpath:" + xpath);
            if (!targetRow) return;
            targetRow.appendChild((function() {
                const result = document.createElement("a");
                result.setAttribute("href", rcmail.url("mail/plugin.nexus_storage_upgrade"));
                result.setAttribute("class", "upgrade");
                result.setAttribute("role", "button");
                result.setAttribute("aria-disabled", "false");
                result.appendChild((function() {
                    const result = document.createElement("span");
                    result.setAttribute("class", "inner");
                    result.textContent = rcmail.gettext("nexus_storage.upgrade");
                    return result;
                })());
                return result;
            })());
            if (ev) ev.target.observer.disconnect();

        };
        const targetRow = document.documentElement.queryElement("xpath:" + xpath);
        if (targetRow) {
            handlerFunction(null);
        } else {
            new sergiosgc.XPathObserver(xpath).addEventListener("xpathobserver.node.new", handlerFunction);
        }
    };

    window.addEventListener('load', () => {
        if (typeof sergiosgc === 'undefined') return;
        linkSoomaProfileDialogQuotaLabel();
        addUpgradeButton();
    });
})();