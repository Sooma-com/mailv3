if (window.rcmail) {
    rcmail.addEventListener('init', function() {
        if (rcmail.task !== 'elasticlogs') {
            return;
        }

        var mode_radios = document.querySelectorAll('input[name="search_mode"]');
        var message_id_fields = document.getElementById('elasticlogs-message-id-fields');
        var sender_recipient_fields = document.getElementById('elasticlogs-sender-recipient-fields');
        var current_results = [];

        function select_mode(mode) {
            mode_radios.forEach(function(radio) {
                radio.checked = (radio.value === mode);
            });
            if (mode === 'message-id') {
                message_id_fields.style.display = '';
                sender_recipient_fields.style.display = 'none';
            } else {
                message_id_fields.style.display = 'none';
                sender_recipient_fields.style.display = '';
            }
        }

        mode_radios.forEach(function(radio) {
            radio.addEventListener('change', function() {
                select_mode(this.value);
            });
        });

        // Set default time range for sender/recipient search: last 24 hours
        var now = new Date();
        var yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        var date_to = document.getElementById('elasticlogs-date-to');
        var date_from = document.getElementById('elasticlogs-date-from');

        if (date_to) {
            date_to.value = to_local_datetime(now);
        }
        if (date_from) {
            date_from.value = to_local_datetime(yesterday);
        }

        // Read GET parameters and pre-populate form
        var url_params = new URLSearchParams(window.location.search);
        var param_message_id = url_params.get('message_id') || '';
        var param_sender_recipient = url_params.get('sender_recipient') || '';
        var param_date_from = url_params.get('date_from') || '';
        var param_date_to = url_params.get('date_to') || '';
        var auto_submit = false;

        if (param_date_from && date_from) {
            date_from.value = param_date_from;
        }
        if (param_date_to && date_to) {
            date_to.value = param_date_to;
        }

        if (param_message_id) {
            document.getElementById('elasticlogs-message-id').value = param_message_id;
            select_mode('message-id');
            auto_submit = true;
        } else if (param_sender_recipient) {
            document.getElementById('elasticlogs-sender-recipient').value = param_sender_recipient;
            select_mode('sender-recipient');
            auto_submit = true;
        }

        // Search button
        var search_btn = document.getElementById('elasticlogs-search-btn');
        if (search_btn) {
            search_btn.addEventListener('click', function() {
                var mode = document.querySelector('input[name="search_mode"]:checked').value;
                var params = { _mode: mode };

                if (mode === 'message-id') {
                    params._message_id = document.getElementById('elasticlogs-message-id').value;
                } else {
                    params._sender_recipient = document.getElementById('elasticlogs-sender-recipient').value;
                    params._date_from = document.getElementById('elasticlogs-date-from').value;
                    params._date_to = document.getElementById('elasticlogs-date-to').value;
                }

                rcmail.http_post('search', params);
            });
        }

        if (auto_submit && search_btn) {
            search_btn.click();
        }

        // Handle search response
        var download_btn = document.getElementById('elasticlogs-download-btn');

        rcmail.addEventListener('plugin.elasticlogs_search_response', function(response) {
            var results_list = document.getElementById('elasticlogs-results-list');
            var no_results = document.getElementById('elasticlogs-no-results');

            results_list.innerHTML = '';
            current_results = [];

            if (!response.results || response.results.length === 0) {
                no_results.style.display = '';
                if (download_btn) download_btn.style.display = 'none';
            } else {
                no_results.style.display = 'none';
                current_results = response.results;
                response.results.forEach(function(entry) {
                    var div = document.createElement('div');
                    div.className = 'elasticlogs-log-entry';
                    div.textContent = entry['@timestamp'] + ' ' + entry.message;
                    results_list.appendChild(div);
                });
                if (download_btn) download_btn.style.display = '';
            }
        });

        // Download button
        if (download_btn) {
            download_btn.addEventListener('click', function() {
                if (!current_results.length) return;

                var lines = current_results.map(function(entry) {
                    return entry['@timestamp'] + ' ' + entry.message;
                });
                var text = lines.join('\n') + '\n';
                var blob = new Blob([text], { type: 'text/plain' });
                var url = URL.createObjectURL(blob);
                var a = document.createElement('a');
                a.href = url;
                a.download = 'smtp-log-' + new Date().toISOString().slice(0, 19).replace(/:/g, '-') + '.txt';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
            });
        }
    });
}

function to_local_datetime(date) {
    var y = date.getFullYear();
    var m = String(date.getMonth() + 1).padStart(2, '0');
    var d = String(date.getDate()).padStart(2, '0');
    var h = String(date.getHours()).padStart(2, '0');
    var min = String(date.getMinutes()).padStart(2, '0');
    return y + '-' + m + '-' + d + 'T' + h + ':' + min;
}
