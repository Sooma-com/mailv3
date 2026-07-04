(function () {
    const toggleElement = (target, display, reposition = false, activeClass = '', event) => {
        if (activeClass && !event.target.classList.contains(activeClass) && !event.target.parentNode.classList.contains(activeClass)) return;
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

    /*
     CSS has no selector for overflowing elements. We need that on toolbars, so 
     programmatically add a class to the element if it overflows.
    */
    const markOverflowing = (target, referenceNode) => {
        if ("undefined" == typeof referenceNode) referenceNode = document.documentElement;
        if ("string" == typeof target) target = referenceNode.queryElement(target);
        if (!target) return;
        target.classList.add("may-overflow");
        target.classList.remove("overflow-x");
        target.classList.remove("overflow-y");
        target.classList.remove("overflow");
        if (target.scrollWidth > target.clientWidth) {
            target.classList.add('overflow-x');
        }
        if (target.scrollHeight > target.clientHeight) {
            target.classList.add('overflow-y');
        }
        if (target.classList.contains('overflow-x') || target.classList.contains('overflow-y')) {
            target.classList.add('overflow');
        }
    }

    const checkOverflowing = () => {
        document.documentElement.queryElements("css:.may-overflow").forEach(markOverflowing);
    }

    const addDomainClassToBody = () => {
        const domain = document.location.hostname.replaceAll(".", "-").toLowerCase();
        document.body.classList.add("domain-" + domain);
    }

    /*
     sergiosgc-js adds a delete confirmation behaviour to any links with the class "delete".
     We don't want that behaviour, so this adds the class "skipconfirmation" to all delete links.
    */
    const disableDeleteConfirmations = () => {
        document.documentElement.queryElements("css:a.delete").forEach(button => {
            button.classList.add("skipconfirmation");
        });
    }

    /*
     Cancel a dialog by clicking outside of it or pressing Escape. This gets attached to handlers
     by the functions that open the dialog.
    */
    const cancelDialog = (target, display, stopPropagation, ev) => {
        if (getComputedStyle(target).opacity === '0') return;
        let candidate = ev.target;
        while (candidate !== document.documentElement) {
            if (candidate === target) return;
            candidate = candidate.parentNode;
        }
        if (ev.type === "click" || (ev.type.startsWith("key") && ev.key === "Escape")) {
            toggleElement(target, display);
            if (stopPropagation) {
                ev.preventDefault();
                ev.stopPropagation();
            }
            return;
        }
    }

    /*
     The login form is displayed in a table, which hampers the ability to style it. Since
     we do not want to touch the templates of the theme, which are to be the same as the original
     elastic theme templates, changes are done in JavaScript.
    */
    const removeLoginFormFromTable = () => {
        const loginForm = document.getElementById('login-form');
        if (!loginForm) return;
        const referenceNode = loginForm.queryElement("css:p.formbuttons");
        loginForm.queryElements("xpath:table//*[self::label or self::input]").forEach(element => {
            referenceNode.parentNode.insertBefore(element, referenceNode);
        });
        loginForm.queryElement("xpath:table").remove();
    };

    /*
     Move source element to destination element. Both source and destination can be DOM elements or 
     queryElement selectors (strings). If they are strings, they are resolved against referenceNode.
     referenceNode defaults to the document element.
    */
    const moveElement = (source, destination, referenceNode) => {
        if ("undefined" == typeof referenceNode) referenceNode = document.documentElement;
        if ("string" == typeof destination) destination = referenceNode.queryElement(destination);
        if ("string" == typeof source) source = referenceNode.queryElement(source);
        if (!source || !destination) return;
        destination.appendChild(source);
    }

    /*
     Move the compose button from the taskmenu to the localmenu. Again, this is done in Javascript in 
     order to preserve the original templates of the elastic theme.
    */
    const moveComposeToLocalMenu = (layoutMenu, localMenu) => {
        let composeButton = layoutMenu
            .queryElements("xpath://div[@id='taskmenu']//a[contains(@class, 'compose') and contains(@href, '&_action=compose')]")
            .map(elm => elm.parentNode);
        if (composeButton.length === 0) return;
        composeButton = composeButton[0];
        localMenu.appendChild(composeButton);
    }

    /*
     Move the mail toolbar from the taskmenu to the localmenu. Again, this is done in Javascript in
     order to preserve the original templates of the elastic theme.
    */
    const moveMailToolbarToLocalMenu = (layoutMenu, localMenu) => {
        layoutMenu
            .queryElements("xpath://div[@id='mailtoolbar']")
            .forEach(localMenu.appendChild.bind(localMenu));
        markOverflowing("css:#mailtoolbar");
    }

    /*
     Move compose's own action toolbar (Guardar/Anexar/Assinatura/Respostas)
     into the localmenu's shared middle slot too - the same slot
     moveMailToolbarToLocalMenu already puts the mail list's toolbar into.
     #mailtoolbar (list/preview) and #messagetoolbar (compose) never exist
     in the DOM at the same time, so they can share that slot - and
     _headermenu.scss's #mailtoolbar rules are written to match both
     selectors for exactly that reason. This is what used to leave the
     localmenu's middle column empty on compose specifically: nothing
     equivalent to moveMailToolbarToLocalMenu ever ran for it (Manuel,
     2026-07-04).
    */
    const moveComposeToolbarToLocalMenu = (layoutMenu, localMenu) => {
        layoutMenu
            .queryElements("xpath://div[@id='messagetoolbar']")
            .forEach(localMenu.appendChild.bind(localMenu));
        markOverflowing("css:#messagetoolbar");
    }

    /*
     Create the Sooma profile menu. 
    */
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
        document.addEventListener("click", cancelDialog.bind(null, profileDialog, "flex", true), { capture: true });
        document.addEventListener("keyup", cancelDialog.bind(null, profileDialog, "flex", true), { capture: true });
        const update_profile_quota = function(element) {
            if (!element.getAttribute("title")) return;
            const matches = /(?<used>[0-9]+(?:\.[0-9]+)?) ?(?<used_unit>[KMGT]B) ?\/ ?(?<capacity>[0-9]+(?:\.[0-9]+)?) ?(?<capacity_unit>[KMGT]B)/.exec(element.getAttribute("title").replaceAll(",", "."));

            if (!matches) return;
            [ "sooma-profile-dialog-quota-label", "sooma-profile-dialog-quota-img", "quota-text"].map(id => document.getElementById(id)).filter( element => element).forEach( element => {
                element.remove();
            });
            const unit_multiplier = function(unit) {
                switch (unit) {
                    case "KB":
                        return 1.0 / (1024.0 * 1024.0);
                    case "MB":
                        return 1.0 / 1024.0;
                    case "GB":
                        return 1.0;
                    case "TB":
                        return 1024.0;
                    default:
                        return 1.0;
                }
            }

            const used = parseFloat(matches.groups.used) * unit_multiplier(matches.groups.used_unit);
            const capacity = parseFloat(matches.groups.capacity) * unit_multiplier(matches.groups.capacity_unit);
            const percent = Math.round(used / capacity * 100);
            row_2.insertBefore((function() {
                const div = document.createElement("div");
                div.setAttribute("id", "quota-text");
                return div;
            })(), row_2.firstChild);
            row_2.insertBefore((function() {
                const img = document.createElement("img");
                img.setAttribute("id", "sooma-profile-dialog-quota-img");
                img.setAttribute("src", "/skins/sooma/images/quota.svg.php?q=" + percent);
                img.setAttribute("alt", "Quota");
                img.setAttribute("height", "40");
                return img;
            })(), row_2.firstChild);
            row_2.insertBefore((function() {
                const div = document.createElement("div");
                div.setAttribute("id", "sooma-profile-dialog-quota-label");
                div.textContent = "Quota " + capacity + " GB";
                return div;
            })(), row_2.firstChild);
        };
        [ document.getElementById("rcmquotadisplay")].filter( element => element).forEach( element => {
            const observer = new MutationObserver(update_profile_quota.bind(null, element));
            observer.observe(element, { attributes: true, childList: true, subtree: true });
            update_profile_quota(element);
        });
    }

    /*
     Create the local menu.
    */
    const createLocalMenu = () => {
        const layoutMenu = document.getRootNode().firstElementChild.queryElement("css:#layout > #layout-menu");
        if (!layoutMenu) return;
        const localMenu = layoutMenu.appendChild(document.createElement("div"));
        localMenu.setAttribute("id", "localmenu");
        moveComposeToLocalMenu(layoutMenu, localMenu);
        moveMailToolbarToLocalMenu(layoutMenu, localMenu);
        moveComposeToolbarToLocalMenu(layoutMenu, localMenu);
        moveElement("css:#layout-list div.searchbar.menu", localMenu);
        createSoomaProfileMenu(layoutMenu);
    }

    /*
     Setup event listeners for a popup menu.
    */
    const setupPopupMenu = (button, menu) => {
        document.addEventListener("click", cancelDialog.bind(null, menu, "block", true), { capture: true });
        document.addEventListener("keyup", cancelDialog.bind(null, menu, "block", true), { capture: true });
        button.addEventListener("click", toggleElement.bind(null, menu, "block", true, "active"));
        menu.addEventListener("click", toggleElement.bind(null, menu, "block", true, null));
    }

    /*
     Setup event listeners for all popup menus.
    */
    const setupPopupMenus = () => {
        document.documentElement
            .queryElements("xpath://*[@data-popup]")
            .map(button => [button, document.getElementById(button.dataset.popup)])
            .filter(([button, menu]) => button && menu)
            .forEach(([button, menu]) => setupPopupMenu(button, menu));
    }

    const setupMailListMenu = () => {
        moveElement("css:.task-mail #layout-list > .header a.button.icon.toolbar-button.refresh", "css:.task-mail #messagelist-header .toolbar.menu");
        document.documentElement.queryElements("css:.task-mail #messagelist-header .toolbar.menu").forEach(menu => {
            menu.appendChild((() => {
                const button = document.createElement("a");
                button.classList.add("button", "icon", "toolbar-button", "unread");
                button.setAttribute("href", "#");
                button.setAttribute("role", "button");
                button.setAttribute("title", rcmail.gettext("showunread"));
                button.addEventListener("click", (event) => {
                    const next_state = rcmail.gui_objects.search_filter.value == 'UNSEEN' ? 'ALL' : 'UNSEEN';
                    rcmail.gui_objects.search_filter.value = next_state;
                    if (next_state == 'UNSEEN') {
                        button.classList.add("active");
                    } else {
                        button.classList.remove("active");
                    }
                    window.UI.prefs.set('message-list-unread-filter', next_state == 'UNSEEN');
                    rcmail.command("search");
                });
                return button;
            })());
        });
        moveElement("css:.task-mail #messagelist-header .toolbar.menu a.options", "css:.task-mail #messagelist-header .toolbar.menu");
        moveElement("css:.task-mail #messagelist-header .toolbar.menu a.refresh", "css:.task-mail #messagelist-header .toolbar.menu");
        markOverflowing("css:.task-mail #messagelist-header .toolbar.menu");
    }

    const setupColumnResizer = () => {
        const mouseDown = (layoutElement, resizer, variable) => {
            resizer.classList.add("active");
        };
        const mouseUp = (layoutElement, resizer, variable) => {
            resizer.classList.remove("active");
            const viewPortWidth = window.innerWidth;
            const desiredWidth = Math.round(100 * resizer.parentNode.getBoundingClientRect().width / viewPortWidth) + "vw";
            const minWidth = resizer.dataset.minWidth ? resizer.dataset.minWidth : "0";
            const maxWidth = resizer.dataset.maxWidth ? resizer.dataset.maxWidth : "100vw";
            const widthToSet = "calc(min(max(" + desiredWidth + ", " + minWidth + "), " + maxWidth + "))";
            layoutElement.style.setProperty(variable, widthToSet);
            window.UI.prefs.set(resizer.dataset.pref_name, widthToSet);
            checkOverflowing();
        };
        const mouseMove = (layoutElement, resizer, variable, event) => {
            if (!resizer.classList.contains("active")) return;
            const desiredWidth = Math.max(0, event.clientX - resizer.parentNode.getBoundingClientRect().left);
            const minWidth = resizer.dataset.minWidth ? resizer.dataset.minWidth : "0";
            const maxWidth = resizer.dataset.maxWidth ? resizer.dataset.maxWidth : "100vw";
            layoutElement.style.setProperty(variable, "calc(min(max(" + desiredWidth + "px, " + minWidth + "), " + maxWidth + "))");
        };
        [
            ["#layout", "#layout-sidebar", "--column-width-sidebar"],
            ["#layout", "#layout-list", "--column-width-list"],
        ].forEach(([layout, column, variable]) => {
            let pref_category = (function () {
                const bodyClasses = document.body.classList;
                if (bodyClasses.contains("task-mail") && bodyClasses.contains("action-compose")) return "mail-compose";
                return "default";
            })();

            const layoutElement = document.documentElement.queryElement("css:" + layout);
            if (!layoutElement) return;
            const resizerContainer = layoutElement.queryElement("css:" + column);
            if (!resizerContainer) return;
            const resizer = resizerContainer.appendChild(document.createElement("div"));
            resizer.classList.add("column-resizer");
            resizer.addEventListener("mousedown", mouseDown.bind(this, layoutElement, resizer, variable));
            resizer.addEventListener("mouseup", mouseUp.bind(this, layoutElement, resizer, variable));
            resizer.addEventListener("mousemove", mouseMove.bind(this, layoutElement, resizer, variable));
            resizer.dataset.pref_name = "column-width/" + pref_category + "/" + layout + "/" + variable;
            resizer.dataset.minWidth = getComputedStyle(resizerContainer).getPropertyValue("--dynamic-min-width");
            resizer.dataset.maxWidth = getComputedStyle(resizerContainer).getPropertyValue("--dynamic-max-width");

            if (window.UI.prefs.get(resizer.dataset.pref_name, false)) {
                layoutElement.style.setProperty(variable, window.UI.prefs.get(resizer.dataset.pref_name));
            }
        });
    }

    const initRoundcube = () => {
        // Sooma's toolbar (icons + labels, wider than elastic's defaults) needs a bit
        // more room in extwin/compose popups than core's defaults (1150/900), or the
        // last toolbar buttons (e.g. "Seguinte") get clipped off the right edge.
        rcmail.set_env({
            popup_width_small: 1000,
            popup_width: 1300
        });

        if (window.UI.prefs.get('list-selection', false)) {
            document.documentElement.queryElements("xpath://*[@data-list]").forEach(list => {
                window.rcmail[list.dataset.list].enable_checkbox_selection();
                list.classList.add('withselection');
            });
        }
        if (window.UI.prefs.get('mail.show.envelope', false)) {
            document.documentElement.queryElements("css:div.header-content").forEach(element => {
                element.classList.add('details-view');
            });
        }
        if (window.UI.prefs.get('message-list-unread-filter', false)) {
            const button = document.documentElement.queryElement("css:.task-mail #messagelist-header .toolbar.menu a.unread");
            rcmail.gui_objects.search_filter.value = 'UNSEEN';
            button.classList.add("active");
            window.setTimeout(window.rcmail.command.bind(rcmail, "search"), 1000);
        }
        document.documentElement.queryElements("css:.menu a.selection").forEach(button => {
            button.classList.remove('disabled');
            button.classList.add('active');
        });
        setupListModeToggle();
        setupSelectMenuAlignment();
    }

    /*
     Segmented Lista/Tópicos control in the main toolbar. Unlike the old
     single a.threads element (permanently styled .disabled regardless of
     whether threaded view was actually on, indistinguishable from a
     genuinely inert control), each segment here is independently clickable
     and switches mode directly.
    */
    const setupListModeToggle = () => {
        document.documentElement.queryElements("css:.toolbar.menu > .listmode-toggle .listmode-option").forEach(option => {
            option.addEventListener('click', (event) => {
                event.preventDefault();
                if (option.classList.contains('active')) {
                    /*
                     Already the active mode — there's no further mode to
                     switch to by clicking it again. For Tópicos specifically
                     (the only segment with a caret sibling in its
                     .dropbutton), reuse that caret's own popup instead of
                     doing nothing: same toggleElement call the caret itself
                     is wired to (see setupPopupMenu above), just invoked
                     directly here since the click landed on the text, not
                     the caret. activeClass is passed as null to skip
                     toggleElement's own "was the clicked element already
                     .active" guard — we've already established that above.
                     Lista has no .dropbutton/caret, so this is a no-op for
                     it — ":scope >" (direct child only) matters here:
                     Lista's parentNode is .listmode-toggle itself, which
                     DOES contain a.dropdown[data-popup] as a descendant
                     (nested one level down inside Tópicos's .dropbutton), so
                     a plain (non-scoped) querySelector would incorrectly
                     match that unrelated caret and wrongly open the popup
                     for Lista too.
                    */
                    const caret = option.parentNode.querySelector(':scope > a.dropdown[data-popup]');
                    const menu = caret && document.getElementById(caret.dataset.popup);
                    if (menu) toggleElement(menu, 'block', true, null, event);
                    return;
                }
                rcmail.command('set-listmode', option.dataset.mode);
            });
        });
        /*
         Both ways of opening #threadselect-menu — clicking the caret
         directly (generic data-popup/setupPopupMenu wiring, above) or
         clicking "Tópicos" text while it's already active (handled just
         above) — leave the menu positioned by toggleElement's default
         reposition logic, centered under wherever the click happened.
         Left-align it instead to the active Tópicos chip's own left edge.
         Not done by changing toggleElement/setupPopupMenu themselves,
         since those are shared by every other popup/dropbutton in this
         skin, not just this one. Instead, listen on .dropbutton itself:
         that fires on the click's bubble phase, after whichever inner
         handler already opened (or closed) the menu, so this only needs
         to correct target.style.left afterwards, not reimplement the
         open/close toggle. The opacity check skips this on the closing
         click, when there's nothing left to reposition.
        */
        document.documentElement.queryElements("css:.toolbar.menu > .listmode-toggle .dropbutton").forEach(dropbutton => {
            dropbutton.addEventListener('click', () => {
                const caret = dropbutton.querySelector(':scope > a.dropdown[data-popup]');
                const menu = caret && document.getElementById(caret.dataset.popup);
                if (menu && getComputedStyle(menu).opacity !== '0') {
                    menu.style.left = dropbutton.getBoundingClientRect().left + 'px';
                }
            });
        });
        updateListModeToggle();
    }

    /*
     "Selecionar" (a.select, data-popup="listselect-menu") has its own
     checkmark icon drawn as its own ::before (_toolbar.scss, fa.$var-check)
     — the leftmost thing in the button, so the button's own bounding-rect
     left edge IS that checkmark's left edge. Same fix as #threadselect-menu
     above and for the same reason: the generic setupPopupMenu/toggleElement
     wiring (data-popup attribute → click → toggleElement) centers the menu
     under wherever the click happened, rather than aligning it to the
     button that opened it. Listening on .toolbar.menu (an ancestor of
     a.select, not a.select itself) guarantees this runs after
     setupPopupMenu's own click listener on the button has already opened
     (or closed) #listselect-menu, regardless of which of the two listeners
     happened to be registered first — bubble-phase listeners on an
     ancestor always run after the target's own, so this only needs to
     correct style.left afterwards rather than reimplement the toggle.
    */
    const setupSelectMenuAlignment = () => {
        document.documentElement.queryElements("css:.toolbar.menu").forEach(toolbar => {
            toolbar.addEventListener('click', (event) => {
                const button = event.target.closest('a.select[data-popup]');
                if (!button) return;
                const menu = document.getElementById(button.dataset.popup);
                if (menu && getComputedStyle(menu).opacity !== '0') {
                    menu.style.left = button.getBoundingClientRect().left + 'px';
                }
            });
        });
    }

    /*
     Keeps the toolbar's .listmode-toggle in sync with the actual list mode:
     called once on init and again after every list reload (rcmail fires
     'listupdate' once set-listmode's AJAX round-trip completes). Also
     toggles "active" on the split-button caret: besides the visual state,
     toggleElement's guard (see setupPopupMenu, above) requires that exact
     class on the clicked element before it will open #threadselect-menu at
     all, so this is what makes the caret genuinely open (or not open) the
     expand/collapse actions menu depending on the current mode.
    */
    const updateListModeToggle = () => {
        const toggle = document.documentElement.queryElement("css:.toolbar.menu > .listmode-toggle");
        if (!toggle) return;
        const mode = rcmail.env.threading ? 'threads' : 'list';
        toggle.queryElements("css:.listmode-option").forEach(option => {
            option.classList.toggle('active', option.dataset.mode == mode);
        });
        const caret = toggle.queryElement("css:a.dropdown");
        if (caret) caret.classList.toggle('active', mode == 'threads');
    }

    const menu_messagelist = (menu) => {
        const dialog = document.getElementById('listoptions-menu').cloneNode(true);
        const sort_col = dialog.queryElement("xpath://select[@name='sort_col']");
        const sort_ord = dialog.queryElement("xpath://select[@name='sort_ord']");
        const mode_toggle = dialog.queryElement("css:.listmode-toggle");
        let current_mode = rcmail.env.threading ? 'threads' : 'list';
        sort_col.value = rcmail.env.sort_col || '';
        sort_ord.value = rcmail.env.sort_order || 'ASC';
        if (mode_toggle) {
            const options = mode_toggle.queryElements("css:.listmode-option");
            options.forEach(option => {
                option.classList.toggle('active', option.dataset.mode == current_mode);
                option.addEventListener('click', (event) => {
                    event.preventDefault();
                    current_mode = option.dataset.mode;
                    options.forEach(o => o.classList.toggle('active', o == option));
                });
            });
        }
        const save_func = (event) => {
            if (event.originalEvent.type.startsWith("key")) {
                document.getElementById('listmenulink').focus();
            }
            rcmail.set_list_options([], sort_col.value, sort_ord.value, current_mode == 'threads' ? 1 : 0);
            return true;
        };
        rcmail.simple_dialog(dialog, 'listoptionstitle', save_func, {
            closeOnEscape: true,
            minWidth: 400
        });
    }

    const menu_toggle = (menu) => {
        if (!menu || !menu.name || (menu.props && menu.props.skinable === false)) return;
        if (menu.name == 'messagelistmenu') return menu_messagelist(menu);
    }

    const allowRendering = () => {
        document.body.style.visibility = 'visible';
    }

    const moveComposeCCandBCCButtons = () => {
        const referenceRow = document.documentElement.queryElement("css:body.task-mail.action-compose #compose_to");
        const ccButton = document.documentElement.queryElement("css:body.task-mail.action-compose #headers-menu a.recipient[data-target='cc']");
        const bccButton = document.documentElement.queryElement("css:body.task-mail.action-compose #headers-menu a.recipient[data-target='bcc']");
        if (!referenceRow || !ccButton || !bccButton) return;
        const inputGroup = referenceRow.queryElement("css:.input-group");
        if (!inputGroup) return;
        // Land Cc/Bcc inside the SAME .input-group-append that already
        // holds Para's "add contact" icon, instead of a new sibling span.
        // Every other header row (Cc, Bcc, Replyto, ...) ends up with
        // exactly one trailing .input-group-append once its "delete" icon
        // is stripped below - keeping Para down to one as well means the
        // CSS grid/subgrid layout in _mail-compose.scss can treat "the
        // row's trailing column" identically everywhere, with no
        // Para-specific exception (2026-07-04).
        const trailingGroup = inputGroup.queryElement("css:.input-group-append");
        if (!trailingGroup) return;
        trailingGroup.setAttribute("id", "compose_recipient_buttons");
        trailingGroup.appendChild(ccButton);
        trailingGroup.appendChild(bccButton);
        document.documentElement.queryElements("css:body.task-mail.action-compose #compose-headers .compose-headers a[data-popup='headers-menu']").forEach(button => {
            button.parentNode.remove();
        });
        const clickHandler = function (event) {
            const field = event.target.dataset.target;
            if (!field) return;
            const row = document.getElementById(`compose_${field}`);
            row.classList.remove("hidden");
            event.target.remove();
        };
        ccButton.addEventListener("click", clickHandler);
        bccButton.addEventListener("click", clickHandler);
        document.documentElement.queryElements("css:body.task-mail.action-compose #compose-headers .compose-headers a.delete").forEach(button => {
            button.parentNode.remove();
        });
    }
    const hideComposeFromIfSingle = () => {
        document.documentElement.queryElements("css:body.task-mail.action-compose #compose-headers #compose_from").forEach(row => {
            if (1 == row.queryElements("css:select#_from option").length) {
                row.classList.add("hidden");
            }
        });
    }
    /*
     Move "From" into the page header bar, above Para - that band used to
     hold #messagetoolbar (now relocated into #localmenu by
     moveComposeToolbarToLocalMenu) and, with the title/back-button/
     task-menu-button already hidden there for compose, had nothing left
     in it. Only relevant with multiple identities - hideComposeFromIfSingle
     above already hides this row entirely on accounts with just one, and
     _mail-compose.scss collapses the header band's own reserved height to
     match, so single-identity accounts don't carry a blank gap for a
     control they'll never see (Manuel, 2026-07-04).
    */
    const moveComposeFromToHeader = () => {
        const header = document.documentElement.queryElement("css:body.task-mail.action-compose #layout-content > .header");
        const fromRow = document.documentElement.queryElement("css:body.task-mail.action-compose #compose_from");
        if (!header || !fromRow) return;
        header.appendChild(fromRow);
    }
    /*
     Replaces the native 5-option #compose-priority <select> (Muito baixa/
     Baixa/Normal/Alta/Muito alta) with 3 colored dots (Baixa/Normal/Alta) -
     Manuel decided to drop the two extremes and make the remaining 3 levels
     visual rather than a dropdown, after research showed every major client
     treats a 5-tier priority scale as a barely-used, often hidden setting
     (2026-07-04). The <select> itself is kept in the DOM, just hidden
     (_mail-compose.scss) - #compose-options's own "formdata" handler
     (submitComposeOptions, below) already reads #compose-priority's .value
     on submit, so the dots only need to drive that value, not replace the
     submission path.
    */
    const buildPriorityDots = () => {
        const select = document.documentElement.queryElement("css:body.task-mail.action-compose #compose-priority");
        if (!select) return;
        const tiers = [
            { value: "4", cls: "low" },
            { value: "0", cls: "normal" },
            { value: "2", cls: "high" },
        ];
        const groupLabel = select.closest(".form-group")?.queryElement("css:label")?.textContent?.trim();
        const wrap = document.createElement("div");
        wrap.className = "priority-dots";
        wrap.setAttribute("role", "radiogroup");
        if (groupLabel) wrap.setAttribute("aria-label", groupLabel);
        const buttons = tiers.map(tier => {
            const option = select.querySelector(`option[value="${tier.value}"]`);
            const label = option ? option.text : tier.cls;
            const btn = document.createElement("button");
            btn.type = "button";
            btn.className = `priority-dot ${tier.cls}`;
            btn.title = label;
            btn.setAttribute("aria-label", label);
            btn.setAttribute("role", "radio");
            btn.dataset.value = tier.value;
            wrap.appendChild(btn);
            return btn;
        });
        const sync = () => {
            buttons.forEach(btn => {
                const active = btn.dataset.value === select.value;
                btn.classList.toggle("active", active);
                btn.setAttribute("aria-checked", active ? "true" : "false");
            });
        };
        buttons.forEach(btn => {
            btn.addEventListener("click", () => {
                select.value = btn.dataset.value;
                select.dispatchEvent(new Event("change", { bubbles: true }));
                sync();
            });
        });
        select.insertAdjacentElement("afterend", wrap);
        sync();
    }
    /*
     Prepare checkboxes for CSS styling. This involves wrapping the checkbox in a label with the
     custom-control class. Styling happens in widgets/_checkbox.scss.

     Originally this only covered the managesieve plugin (filters/vacation/forward), so every
     other Settings page kept native, unstyled checkboxes: General, Mailbox, Mail View,
     Composing, Addressbook, Server, Encryption (enigma), Calendar prefs, and the folder
     subscription list all render bare <input type="checkbox"> with no wrapping <label> and no
     form-check-input class (see rcube_output::prefs_field() / actions/settings/folders.php in
     core) — so the "action-plugin-managesieve" scoping was excluding them. Scoping to
     body.task-settings as a whole picks up all of those consistently.
    */
    const wrapCheckboxes = () => {
        document.documentElement.queryElements("css:input[type='checkbox']").forEach(checkbox => {
            // if (checkbox.parentNode.tagName == "LABEL") return;
            const xCalendarApp = Boolean(document.documentElement.queryElement("css:body.task-xcalendar"));
            const settingsTask = Boolean(document.documentElement.queryElement("css:body.task-settings"));
            if (!xCalendarApp && !settingsTask && !checkbox.classList.contains("form-check-input")) return;
            const label = document.createElement("label");
            label.classList.add("custom-control");
            checkbox.parentNode.replaceChild(label, checkbox);
            label.appendChild(checkbox);
        });
    }
    /*
     Setup tabbed content. We are expecting a structure like this:
      <div class="tabbed">
        <fieldset>
          <legend>Tab 1</legend>
          <div>Content 1</div>
        </fieldset>
        <fieldset>
          <legend>Tab 2</legend>
          <div>Content 2</div>
        </fieldset>
      </div>
     And we produce a structure like this:
      <div class="tabbed">
        <div class="tab-controls">
          <div class="tab-control active"><legend>Tab 1</legend></div>
          <div class="tab-control"><legend>Tab 2</legend></div>
        </div>
        <fieldset class="active">
          <div>Content 1</div>
        </fieldset>
        <fieldset>
          <div>Content 2</div>
        </fieldset>
      </div>
     With event handlers to switch between tabs (setting active class on the tab-control and the fieldset).
     Actually showing/hiding the tabs is done by CSS (widgets/_tabbed.scss).
    */
    const setupTabbed = () => {
        const handleClicked = (event) => {
            let target = event.target;
            while (target && !target.classList.contains("tab-control")) {
                target = target.parentNode;
            }
            if (!target) return;
            target.parentNode.queryElements("xpath:./div").filter(element => element.classList.contains("tab-control")).forEach(element => {
                element.classList.remove("active");
                element.tab.classList.remove("active");
            });
            target.classList.add("active");
            target.tab.classList.add("active");
        }
        document.documentElement.queryElements("css:.tabbed:has(>fieldset):not(:has(.tab-controls))").forEach(tabbed => {
            const tabControls = document.createElement("div");
            tabbed.prepend(tabControls);
            tabControls.classList.add("tab-controls");
            tabbed.queryElements("xpath:./fieldset").forEach(fieldset => {
                const legend = fieldset.queryElement("xpath:./legend");
                if (!legend) return;
                const tabControl = tabControls.appendChild(document.createElement("div"));
                tabControl.classList.add("tab-control");
                tabControl.tab = fieldset;
                tabControl.appendChild(legend);
                tabControl.addEventListener("click", handleClicked);
            });
            [tabControls.queryElement("xpath:./div[@class='tab-control']")].filter(element => element).forEach(element => {
                element.dispatchEvent(new CustomEvent("click", { bubbles: true, cancelable: true }));
            });
        });
    }
    /*
     Rearrange the compose/edit form to move the headers to the top and the content to the bottom.
    */
    const rearrangeContactEditForm = () => {
        const namesDiv = document.documentElement.queryElement("css:body.task-addressbook.action-edit #contacthead > .names,body.task-addressbook.action-add #contacthead > .names ");
        if (!namesDiv) return;
        namesDiv.parentNode.queryElements("xpath:./div").filter(element => element.classList.contains("row")).forEach(element => namesDiv.appendChild(element));
    }


    /*
     Tag the address form with an address-form class for styling.
     */
    const tagAddressForm = () => {
        const handlerFunction = () => {
            document.documentElement.queryElements("css:body.task-addressbook .content").forEach(control => {
                if (![
                    "ff_street",
                    "ff_locality",
                    "ff_zipcode",
                    "ff_country",
                    "ff_region",
                ].every(className => Boolean(control.queryElement("xpath:./*[contains(concat(' ',normalize-space(@class),' '),' " + className + " ')]")))) return;
                const addressForm = document.createElement("div");
                addressForm.classList.add("address-form");
                while (control.firstChild) {
                    addressForm.appendChild(control.firstChild);
                }
                control.appendChild(addressForm);
            })
        };

        (new sergiosgc.XPathObserver("//*[contains(concat(' ',normalize-space(@class),' '),' content ')]"))
            .addEventListener("xpathobserver.node.new", handlerFunction);
        handlerFunction();
    }

    const clickOnContactPhotoFireUpload = () => {
        [
            document.documentElement.queryElement("css:body.task-addressbook.action-edit #contactphoto #contactpic"),
            document.documentElement.queryElement("css:body.task-addressbook.action-add #contactphoto #contactpic")
        ].filter(element => element).forEach(element => {
            element.addEventListener("click", () => {
                document.getElementById("upload-formInput").click();
            });
        });
    }

    const tagDefaultPhotoOnContactPic = () => {

        const handlerFunction = (img, ev) => {
            if (ev && 0 == ev.filter(mutation => mutation.type == "attributes" && mutation.attributeName == "src").length) return;
            if (img.src.indexOf(rcmail.env.photo_placeholder) != -1) {
                img.classList.add("default-photo");
            } else {
                img.classList.remove("default-photo");
            }
        };
        [
            document.documentElement.queryElement("css:.formcontent .contact-header #contactphoto #contactpic>img")
        ].filter(element => element).forEach(element => {
            handlerFunction(element);
            const observer = new MutationObserver(handlerFunction.bind(this, element));
            observer.observe(element, { attributes: true, childList: false, subtree: false });
            const deleteButton = element.parentNode.appendChild(document.createElement("a"));
            deleteButton.classList.add("button", "icon", "delete");
            deleteButton.addEventListener("click", (e) => {
                rcmail.command('delete-photo', '', this, e);
                e.preventDefault();
                e.stopPropagation();
            });
        });
    }

    const clickOnLogoReturnToMail = () => {
        document.documentElement.queryElements("css:#layout-menu > .popover-header").map(elm => {
            elm.addEventListener("click", () => {
                document.location.href = "/?_task=mail&_mbox=INBOX";
            });
        });
    };

    const submitComposeOptions = () => {
        document.documentElement.queryElements("css:body.task-mail.action-compose #compose-content > form").forEach( form => form.addEventListener("formdata", function(ev) {
            document
            .documentElement
            .queryElements("css:#compose-options input, #compose-options select, #compose-options textarea")
            .filter( (input) => input.checked !== false )
            .map( (input) => ev.formData.set(input.name, input.value) );
        }));
    }

    /*
     Main entry point.
    */
    window.addEventListener('load', () => {
        if (window.UI.loaded) return;
        window.UI.loaded = true;
        addDomainClassToBody();
        disableDeleteConfirmations();
        removeLoginFormFromTable();
        createLocalMenu();
        setupPopupMenus();
        // setupColumnResizer must run before setupMailListMenu: it restores
        // any saved drag-resized column width (window.UI.prefs), and
        // setupMailListMenu's markOverflowing() measures the messagelist
        // toolbar's width to decide text-vs-icons-only mode. Doing it in the
        // other order (as before) measured against the pre-restore/default
        // width on every full page load, so a previously narrowed list
        // column never got the icon-only ".overflow" class and its full
        // text labels stayed and overflowed the header until the next
        // manual drag (which does call checkOverflowing()).
        setupColumnResizer();
        setupMailListMenu();
        moveComposeCCandBCCButtons();
        hideComposeFromIfSingle();
        moveComposeFromToHeader();
        buildPriorityDots();
        wrapCheckboxes();
        setupTabbed();
        rearrangeContactEditForm();
        tagAddressForm();
        clickOnContactPhotoFireUpload();
        tagDefaultPhotoOnContactPic();
        clickOnLogoReturnToMail();
        submitComposeOptions();
        if ('loaded' in rcmail && rcmail.loaded) {
            initRoundcube.bind(this)();
        } else {
            rcmail.addEventListener("init", initRoundcube.bind(this));
        }
        rcmail
            .addEventListener('menu-open', menu_toggle.bind(this))
            .addEventListener('menu-close', menu_toggle.bind(this))
            .addEventListener('listupdate', updateListModeToggle);

        allowRendering();
    });

})();
window.UI = {
    loaded: false,
    prefs: {
        current: null,
        key: 'sooma-prefs',
        fetch: function () {
            if (this.current === null) {
                this.current = localStorage.getItem(this.key);
                if (this.current) {
                    try {
                        this.current = JSON.parse(this.current);
                    } catch (e) {
                        this.current = {};
                    }
                } else {
                    this.current = {};
                }
            }
            return this.current;
        },
        set: function (name, value) {
            this.fetch();
            this.current[name] = value;
            localStorage.setItem(this.key, JSON.stringify(this.current));
        },
        get: function (name, defaultValue) {
            this.fetch();
            if (name in this.current) return this.current[name];
            return defaultValue;
        },
    },
    toggle_list_selection: function (button, list) {
        if (button.classList.contains('disabled')) return;
        const listElement = document.getElementById(list);
        if (!listElement) return;
        if (!'list' in listElement.dataset) return;
        if (!listElement.dataset.list in rcmail) return;
        const next_state = !this.prefs.get('list-selection', false);
        if (next_state) {
            rcmail[listElement.dataset.list].enable_checkbox_selection();
            listElement.classList.add('withselection');
        } else {
            listElement.classList.remove('withselection');
        }
        this.prefs.set('list-selection', next_state);
    },
    headers_show: function (toggle) {
        const key = 'mail.show.envelope';
        const nextState = toggle ? !this.prefs.get(key, false) : this.prefs.get(key, false);

        document.documentElement.queryElements('css:div.header-content').forEach(element => {
            if (nextState) {
                element.classList.add('details-view');
            } else {
                element.classList.remove('details-view');
            }
        });
        this.prefs.set(key, nextState);
    },
    recipient_selector: function (field, opts) {
        if (!opts) opts = {};

        var title = opts.title || 'insertcontact',
            dialog = document.getElementById('recipient-dialog'),
            parent = dialog.parentNode,
            close_func = function (event) {
                console.log(event);
                if (dialog.checkVisibility()) {
                    rcmail.env.recipient_dialog.dialog('close');
                }
                const field = event.field;
                const recipientsToAdd = event.recipients.join(", ");
                document.documentElement.queryElements(`css:#compose_${field} .recipient-input > input`).forEach(input => {
                    input.value = [input.value, recipientsToAdd].filter(s => s.trim().length).join(", ");
                    input.dispatchEvent(new Event('change'));
                });
            },
            insert_func = function () {
                if (opts.action) {
                    opts.action();
                    close_func();
                    return;
                }

                rcmail.command('add-recipient');
            };

        if (!rcmail.env.recipient_selector_initialized) {
            rcmail.addEventListener('add-recipient', close_func);
            rcmail.env.recipient_selector_initialized = true;
        }

        if (field) {
            rcmail.env.focused_field = '#_' + field;
        }

        rcmail.contact_list.clear_selection();
        rcmail.contact_list.multiselect = 'multiselect' in opts ? opts.multiselect : true;

        rcmail.env.recipient_dialog = rcmail.simple_dialog(dialog, title, insert_func, {
            button: rcmail.gettext(opts.button || 'insert'),
            button_class: opts.button_class || 'insert recipient',
            height: 600,
            classes: {
                'ui-dialog-content': 'p-0' // remove padding on dialog content
            },
            open: function () {
                // Don't want focus in the search field, we focus first contacts source record instead
                [document.documentElement.queryElement("css:#directorylist a")]
                    .filter(element => element)
                    .forEach(element => element.focus());
            },
            close: function () {
                parent.appendChild(dialog);
                this.remove();
                // (opts.focus || rcmail.env.focused_field).focus();
            }
        });
    },
    form_errors: function (tips) {
        tips.map( tip => {
            const input = document.getElementById(tip[0]);
            console.log(input);
            if (!input) return;
            input.classList.add('is-invalid');
            const error = document.createElement('span');
            error.classList.add('form-error');
            error.textContent = tip[2];
            console.log(input.insertAdjacentElement('afterend', error));
        });
    }
}
