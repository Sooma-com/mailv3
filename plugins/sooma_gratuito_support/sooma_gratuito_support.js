/**
 * Sooma gratuito support plugin: ask for confirmation before destructive account actions.
 */
window.rcmail && rcmail.addEventListener('init', function () {
    $('form.sgs-action[data-confirm]').on('submit', function () {
        return confirm($(this).attr('data-confirm'));
    });
});
