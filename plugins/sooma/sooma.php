<?php
/**
 * Reset Password Plugin for Roundcube
 *
 * @author Sérgio Carvalho <daf@sooma.com>
 *
 * Copyright (C) Sooma.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */
class sooma extends rcube_plugin
{
    public $rc;
    public $_db = null;

    public function init()
    {
        $this->rc = rcmail::get_instance();
        $this->load_config();
        $this->add_texts('localization/');
        $this->include_stylesheet('css.php');
        $this->add_hook('html_editor', [$this, 'html_editor']);
        $this->include_script('js/editor_toolbar.js');

        // Override the core pt_PT 'list' label ("Em lista" -> "Lista") to
        // fit the shorter Lista/Tópicos segmented toggle from the
        // skin-design toolbar redesign - the pill has no room for the
        // longer default string. Was previously a direct edit to
        // program/localization/pt_PT/labels.inc; moved here so it survives
        // a Roundcube core upgrade instead of being silently reverted by
        // one, same reasoning as html_editor() above.
        //
        // add_texts() can't do this: it always prefixes new labels with
        // this plugin's domain ('sooma.list'), so it can only add new
        // labels, not override an existing core one. Calling
        // rcube::load_language() directly with the $merge argument is the
        // one path in core that array_merge()s over already-loaded texts
        // instead of only filling in missing keys (see rcube::load_language()
        // in program/lib/Roundcube/rcube.php) - it's safe to call here
        // regardless of whether core has already lazily loaded its own
        // labels.inc via gettext()/text_exists() or not, since
        // load_language() loads the base files on first call either way
        // and applies $merge in that same call (Manuel, 2026-07-06).
        $this->rc->load_language(null, [], ['list' => 'Lista']);
    }

    // Adds TinyMCE's own "fullscreen" plugin to every rich-text editor
    // Roundcube renders (compose, identity signatures, canned responses) -
    // Manuel wants a way to expand the message body to fill the window,
    // since the compose sidebar/headers otherwise permanently eat into
    // that space. TinyMCE ships this natively (program/js/tinymce/plugins/
    // fullscreen), Roundcube core just never enables it. Hooking
    // html_editor here - rather than editing program/js/editor.js directly
    // - uses the exact extension point core already provides for this
    // (extra_plugins, appended into its plugins string via program/js/
    // editor.js's own $.each loop), so this survives a Roundcube core
    // upgrade instead of being silently reverted by one (Manuel,
    // 2026-07-05).
    //
    // Only `extra_plugins` is used here now, not `extra_buttons` - the
    // actual "fullscreen" toolbar button placement is handled entirely by
    // editor_toolbar.js's full toolbar-string override (it's listed there
    // as a normal, native, last-position button, no longer pinned/
    // absolutely-positioned outside the toolbar via a separate
    // editor_fullscreen.js + CSS hack, both removed - see that file's own
    // comment for why and what tradeoff that implies). Registering it via
    // extra_buttons here too would be redundant (editor_toolbar.js's
    // override replaces the whole toolbar string it would have spliced
    // into anyway) - but still needed on identity/response editors, which
    // keep Roundcube's stock toolbar and were never part of this redesign,
    // so extra_buttons stays for those.
    //
    // Also trims a handful of plugins - charmap/code/directionality/media/
    // searchreplace - out of the *compose* editor specifically (identity
    // signature and canned-response editors are left untouched). This is
    // the server-side half of the compose toolbar redesign: editor_toolbar.
    // js fully replaces the compose toolbar's button *string* (dropping the
    // buttons for these), but a toolbar string alone doesn't stop TinyMCE
    // from still fetching+loading each plugin's JS in the background - the
    // plugin list is a separate conf key. Removing them here too means one
    // less each of the corresponding plugin.min.js requests per compose
    // window, for buttons that no longer have anywhere to appear in the UI
    // anyway (Manuel, 2026-07-05).
    //
    // Gated on `$args['mode']` (see program/actions/mail/compose.php's
    // self::html_editor() call vs identity_edit.php's/response_edit.php's
    // own calls, each passing a different `$mode` string into this same
    // exec_hook('html_editor', ...) - the only server-side signal
    // distinguishing which editor instance this is) so this doesn't also
    // strip these from the identity/response editors, whose toolbars
    // weren't part of this redesign and still use Roundcube's stock full
    // set. Uses `disabled_plugins`, the same core-provided mechanism as
    // extra_plugins above (`program/include/rcmail_action.php`'s
    // html_editor() consumes it via a plain string search-and-replace on
    // conf.plugins) - safe today since none of these 5 names are a
    // substring of another plugin already earlier in that string, but
    // that's a real constraint of how core implements this, worth
    // re-checking if Roundcube's own default plugin list ever changes.
    public function html_editor($args)
    {
        $args['extra_plugins'][] = 'fullscreen';
        $args['extra_buttons'][] = 'fullscreen';

        if (!in_array($args['mode'], ['identity', 'response'])) {
            $args['disabled_plugins'] = array_merge($args['disabled_plugins'], [
                'charmap', 'code', 'directionality', 'media', 'searchreplace',
            ]);
        }

        return $args;
    }

    public function db() {
        if ($this->_db === null) {
            $rcmail = rcmail::get_instance();
            $db_config = $rcmail->config->get('sooma_db');
            $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s', 
                $db_config['host'], 
                $db_config['port'], 
                $db_config['dbname']
            );
            $db = new PDO($dsn, $db_config['username'], $db_config['password']);
            $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->_db = $db;
        }
        return $this->_db;
    }
    public function db_exec($query, $params) {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue($key, $value);
        $stmt->execute();
    }

    public function db_query_row($query, $params) {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue($key, $value);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        return $result;
    }
}