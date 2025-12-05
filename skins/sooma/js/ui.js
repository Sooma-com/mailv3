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

    const markOverflowing = (target, referenceNode) => {
        if ("undefined" == typeof referenceNode) referenceNode = document.documentElement;
        if ("string" == typeof target) target = referenceNode.queryElement(target);
        if (!target) return;
        console.log(target);
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

    const disableDeleteConfirmations = () => {
        document.documentElement.queryElements("css:a.delete").forEach(button => {
            button.classList.add("skipconfirmation");
        });
    }

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

    const moveMailToolbarToLocalMenu = (layoutMenu, localMenu) => {
        layoutMenu
            .queryElements("xpath://div[@id='mailtoolbar']")
            .forEach(localMenu.appendChild.bind(localMenu));
        markOverflowing("css:#mailtoolbar");
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
        document.addEventListener("click", cancelDialog.bind(null, profileDialog, "flex", true), { capture: true });
        document.addEventListener("keyup", cancelDialog.bind(null, profileDialog, "flex", true), { capture: true });
    }

    const createLocalMenu = () => {
        const layoutMenu = document.getRootNode().firstElementChild.queryElement("css:#layout > #layout-menu");
        if (!layoutMenu) return;
        const localMenu = layoutMenu.appendChild(document.createElement("div"));
        localMenu.setAttribute("id", "localmenu");
        moveComposeToLocalMenu(layoutMenu, localMenu);
        moveMailToolbarToLocalMenu(layoutMenu, localMenu);
        moveElement("css:#layout-list div.searchbar.menu", localMenu);
        createSoomaProfileMenu(layoutMenu);
    }

    const setupPopupMenu = (button, menu) => {
        document.addEventListener("click", cancelDialog.bind(null, menu, "block", true), { capture: true });
        document.addEventListener("keyup", cancelDialog.bind(null, menu, "block", true), { capture: true });
        button.addEventListener("click", toggleElement.bind(null, menu, "block", true, "active"));
        menu.addEventListener("click", toggleElement.bind(null, menu, "block", true, null));
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
    }

    const menu_messagelist = (menu) => {
        const dialog = document.getElementById('listoptions-menu').cloneNode(true);
        const sort_col = dialog.queryElement("xpath://select[@name='sort_col']");
        const sort_ord = dialog.queryElement("xpath://select[@name='sort_ord']");
        const thread_mode = dialog.queryElement("xpath://select[@name='mode']");
        sort_col.value = rcmail.env.sort_col || '';
        sort_ord.value = rcmail.env.sort_order || 'ASC';
        thread_mode.value = rcmail.env.threading ? 'threads' : 'list';
        const save_func = (event) => {
            if (event.originalEvent.type.startsWith("key")) {
                document.getElementById('listmenulink').focus();
            }
            rcmail.set_list_options([], sort_col.value, sort_ord.value, thread_mode.value == 'threads' ? 1 : 0);
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
        referenceRow.parentNode.insertBefore((function () {
            const row = document.createElement("div");
            row.setAttribute("id", "compose_recipient_buttons");
            row.classList.add("form-group", "row");
            row.appendChild((function () {
                const label = document.createElement("label");
                label.classList.add("col-2", "col-form-label");
                return label;
            })());
            row.appendChild((function () {
                const div = document.createElement("div");
                div.classList.add("col-10");
                div.appendChild(ccButton);
                div.appendChild(bccButton);
                return div;
            })());
            return row;
        })(), referenceRow.nextSibling);
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
    const wrapCheckboxes = () => {
        document.documentElement.queryElements("css:input[type='checkbox']").forEach(checkbox => {
            if (checkbox.parentNode.tagName == "LABEL") return;
            if (!checkbox.classList.contains("form-check-input")) return;
            const label = document.createElement("label");
            label.classList.add("custom-control");
            checkbox.parentNode.replaceChild(label, checkbox);
            label.appendChild(checkbox);
        });
    }


    window.addEventListener('load', () => {
        if (window.UI.loaded) return;
        window.UI.loaded = true;
        disableDeleteConfirmations();
        removeLoginFormFromTable();
        createLocalMenu();
        setupPopupMenus();
        setupMailListMenu();
        setupColumnResizer();
        moveComposeCCandBCCButtons();
        hideComposeFromIfSingle();
        wrapCheckboxes();
        if ('loaded' in rcmail && rcmail.loaded) {
            initRoundcube.bind(this)();
        } else {
            rcmail.addEventListener("init", initRoundcube.bind(this));
        }
        rcmail
            .addEventListener('menu-open', menu_toggle.bind(this))
            .addEventListener('menu-close', menu_toggle.bind(this));

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
    }
}
