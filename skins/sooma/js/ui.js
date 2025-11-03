(function () {
    const toggleElement = (target, display, reposition = false, activeClass = '', event) => {
        if (activeClass && !event.target.classList.contains(activeClass)) return;
        style = getComputedStyle(target);
        if (style.opacity === '0') {
            target.style.display = display;
            target.style.opacity = 1;
            if (reposition) {
                target.style.position = 'fixed';
                const rect = target.getBoundingClientRect();
                const mouseX = event?.clientX || window.innerWidth / 2;
                const mouseY = event?.clientY || window.innerHeight / 2;

                target.style.left = Math.max(0, Math.min(mouseX - rect.width / 2, window.innerWidth - rect.width)) + 'px';
                target.style.top = "calc(" + mouseY + "px + 1rem)";
            }
        } else {
            target.style.opacity = 0;
            window.setTimeout(() => {
                target.style.display = 'none';
            }, 200);
        }
    }

    const markOverflowing = (target, referenceNode) => {
        if ("undefined" == typeof referenceNode) referenceNode = document.documentElement;
        if ("string" == typeof target) target = referenceNode.queryElement(target);
        if (!target) return;
        if (target.scrollWidth > target.clientWidth) {
            target.classList.add('overflow-x');
        } else {
            target.classList.remove('overflow-x');
        }
        if (target.scrollHeight > target.clientHeight) {
            target.classList.add('overflow-y');
        } else {
            target.classList.remove('overflow-y');
        }
        if (target.classList.contains('overflow-x') || target.classList.contains('overflow-y')) {
            target.classList.add('overflow');
        } else {
            target.classList.remove('overflow');
        }
    }

    const cancelDialog = (target, display, ev) => {
        if (getComputedStyle(target).opacity === '0') return;
        let candidate = ev.target;
        while (candidate !== document.documentElement) {
            if (candidate === target) return;
            candidate = candidate.parentNode;
        }
        if (ev.type === "click" || (ev.type.startsWith("key") && ev.key === "Escape")) {
            toggleElement(target, display);
            ev.preventDefault();
            ev.stopPropagation();
            return;
        }
    }

    const removeLoginFormFromTable = () => {
        const loginForm = document.getElementById('login-form');
        if (!loginForm) return;
        const referenceNode = loginForm.queryElement("css:p.formbuttons");
        loginForm.queryElements("xpath:table//*[self::label or self::input]").forEach(element => {
            referenceNode.parentNode.insertBefore(element, referenceNode);
        });
        loginForm.queryElement("xpath:table").remove();
    };

    const moveElement = (source, destination, referenceNode) => {
        if ("undefined" == typeof referenceNode) referenceNode = document.documentElement;
        if ("string" == typeof destination) destination = referenceNode.queryElement(destination);
        if ("string" == typeof source) source = referenceNode.queryElement(source);
        if (!source || !destination) return;
        destination.appendChild(source);
    }

    const moveComposeToLocalMenu = (layoutMenu, localMenu) => {
        let composeButton = layoutMenu
            .queryElements("xpath://div[@id='taskmenu']//a[contains(@class, 'compose') and contains(@href, '&_action=compose')]")
            .map(elm => elm.parentNode);
        if (composeButton.length === 0) return;
        composeButton = composeButton[0];
        localMenu.appendChild(composeButton);
    }

    const createSoomaProfileMenu = (layoutMenu) => {
        const taskmenu = layoutMenu.queryElement("css:#taskmenu");
        if (!taskmenu) return;
        const profileMenu = taskmenu.appendChild(document.createElement("div"));
        profileMenu.setAttribute("id", "sooma-profile");
        const img = profileMenu.appendChild(document.createElement("img"));
        img.setAttribute("src", "/skins/sooma/images/john-doe.svg");
        img.setAttribute("alt", "Profile");
        const profileDialog = taskmenu.appendChild(document.createElement("div"));
        profileDialog.setAttribute("id", "sooma-profile-dialog");
        const row_1 = profileDialog.appendChild(document.createElement("div"));
        row_1.classList.add("sooma-profile-dialog-row-1");
        const row_2 = profileDialog.appendChild(document.createElement("div"));
        row_2.classList.add("sooma-profile-dialog-row-2");
        const profileImage = row_1.appendChild(document.createElement("img"));
        profileImage.setAttribute("id", "sooma-profile-dialog-profile-image");
        profileImage.setAttribute("class", "sooma-profile-dialog-profile-image");
        profileImage.setAttribute("src", "/skins/sooma/images/john-doe.svg");
        profileImage.setAttribute("alt", "Profile");
        moveElement("css:#sooma-profile-dialog-identity", row_1);
        moveElement("css:#taskmenu a[href='/?_task=settings']", row_1);
        moveElement("css:#taskmenu a.theme", row_2);
        moveElement("css:#taskmenu a.about", row_2);
        moveElement("css:#taskmenu a.logout", row_2);
        profileMenu.addEventListener("click", toggleElement.bind(null, profileDialog, "flex", false, null));
        document.addEventListener("click", cancelDialog.bind(null, profileDialog, "flex"), { capture: true });
        document.addEventListener("keyup", cancelDialog.bind(null, profileDialog, "flex"), { capture: true });
    }

    const createLocalMenu = () => {
        const layoutMenu = document.getRootNode().firstElementChild.queryElement("css:#layout > #layout-menu");
        if (!layoutMenu) return;
        const localMenu = layoutMenu.appendChild(document.createElement("div"));
        localMenu.setAttribute("id", "localmenu");
        moveComposeToLocalMenu(layoutMenu, localMenu);
        moveElement("css:#layout-list div.searchbar.menu", localMenu);
        createSoomaProfileMenu(layoutMenu);
    }

    const setupPopupMenu = (button, menu) => {
        document.addEventListener("click", cancelDialog.bind(null, menu, "block"), { capture: true });
        document.addEventListener("keyup", cancelDialog.bind(null, menu, "block"), { capture: true });
        button.addEventListener("click", toggleElement.bind(null, menu, "block", true, "active"));
    }

    const setupPopupMenus = () => {
        document.documentElement
            .queryElements("xpath://*[@data-popup]")
            .map(button => [button, document.getElementById(button.dataset.popup)])
            .filter(([button, menu]) => button && menu)
            .forEach(([button, menu]) => setupPopupMenu(button, menu));
    }

    const setupMailListMenu = () => {
        moveElement("css:.task-mail #layout-list > .header a.button.icon.toolbar-button.refresh", "css:.task-mail #messagelist-header .toolbar.menu");
        markOverflowing("css:.task-mail #messagelist-header .toolbar.menu");
    }

    const allowRendering = () => {
        document.body.style.visibility = 'visible';
    }


    window.addEventListener('load', () => {
        removeLoginFormFromTable();
        createLocalMenu();
        setupPopupMenus();
        setupMailListMenu();


        allowRendering();
    });

})();
