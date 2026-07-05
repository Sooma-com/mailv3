/**
 * Replaces the compose editor's toolbar button string wholesale, to match
 * Manuel's requested reading order and drop a few buttons that didn't earn
 * their place (ltr/rtl, media, charmap, code, searchreplace, alignjustify -
 * see the conversation that led here: media in particular doesn't survive
 * most recipients' email clients, so keeping it risked lawyers embedding
 * something that just breaks on arrival; alignjustify is a documented
 * readability anti-pattern per WCAG SC 1.4.8, not just rarely used).
 *
 * Why a full replacement instead of Roundcube's own extra_buttons/
 * disabled_buttons hook mechanism (sooma.php's html_editor hook): those
 * only support two narrow operations - appending a button at one fixed
 * "$extra" slot in core's own toolbar string, or stripping a button via a
 * naive string search-and-replace. Neither can *reorder* buttons core
 * already placed (e.g. moving undo/redo from the end to the front, ahead
 * of bold/italic/underline - matching how Word/Docs/Gmail all put
 * undo/redo far-left rather than buried after a dozen other icons).
 * Fully overriding `toolbar` via window.rcmail_editor_settings - the same
 * sanctioned skin/plugin extension point - runs *after* core assembles its
 * own toolbar string (program/js/editor.js's own `if
 * (window.rcmail_editor_settings) $.extend(conf,
 * window.rcmail_editor_settings)`, right before the editor is
 * constructed), so it simply replaces the whole thing rather than fighting
 * core's own assembly logic (Manuel, 2026-07-05).
 *
 * "fullscreen" is placed here as a genuine, normal, last toolbar button -
 * NOT pinned/absolutely-positioned outside the toolbar flow like an
 * earlier version of this feature did (see git history:
 * editor_fullscreen.js + widgets/_editor-fullscreen.scss, both removed).
 * That approach was built specifically so fullscreen could never get
 * swallowed by TinyMCE's toolbar_drawer:'sliding' overflow ("...") drawer,
 * which hides the *rightmost* buttons first once a row doesn't fit -
 * exactly the failure mode for a button whose whole purpose is "give me
 * more room". Measured live (in-page reinit + width sweep, not guessed):
 * dropping alignjustify plus this reorder keeps fullscreen visible at the
 * two largest Portuguese desktop screen-resolution clusters (1920x1080
 * ~30%, 1536x864 ~12%, per StatCounter), but it still gets pushed into
 * overflow at the 1366x768 cluster (~7%) and below. Manuel's call
 * (2026-07-05): lawyers on desktop skew toward native clients
 * (Outlook/Thunderbird) over webmail and away from general-population
 * screen-size stats, so that residual risk was accepted in favour of the
 * simpler, non-hacky native placement - see memory
 * mailv3-mobile-skin-followup.md for the related follow-up this surfaced
 * (genuine mobile/small-tablet users are a separate, more real population
 * than narrow-desktop-window users, and still need Roundcube's own mobile
 * mode revisited).
 *
 * Gated to task=mail specifically (rather than every editor instance on
 * every page) so this doesn't also rewrite the identity-signature and
 * canned-response editors' toolbars on Settings pages - those live under
 * task=settings and were never part of this redesign, and
 * window.rcmail_editor_settings has no per-instance "which editor is this"
 * signal of its own (it's read fresh at each `new rcube_text_editor(...)`
 * call, but is otherwise just one shared global object) - task is the one
 * page-level fact this script can reliably check up front instead.
 */
(function () {
    if (rcmail.env.task !== 'mail') {
        return;
    }

    var existing_settings = window.rcmail_editor_settings || {};

    window.rcmail_editor_settings = $.extend({}, existing_settings, {
        toolbar: 'undo redo'
            + ' | bold italic underline'
            + ' | fontselect fontsizeselect'
            + ' | forecolor backcolor'
            + ' | bullist numlist outdent indent blockquote'
            + ' | alignleft aligncenter alignright'
            + ' | link image table'
            + ' | removeformat'
            + ' | fullscreen'
    });
})();
