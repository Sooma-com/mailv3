if (window.rcmail) {
    rcmail.addEventListener('init', function() {
        if (rcmail.task !== 'elasticlogs') {
            return;
        }

        var mode_radios = document.querySelectorAll('input[name="search_mode"]');
        var outbound_fields = document.getElementById('elasticlogs-outbound-fields');
        var inbound_fields = document.getElementById('elasticlogs-inbound-fields');

        mode_radios.forEach(function(radio) {
            radio.addEventListener('change', function() {
                if (this.value === 'outbound') {
                    outbound_fields.style.display = '';
                    inbound_fields.style.display = 'none';
                } else {
                    outbound_fields.style.display = 'none';
                    inbound_fields.style.display = '';
                }
            });
        });

        // Set default time range for inbound: last 24 hours
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

        // Search button
        var search_btn = document.getElementById('elasticlogs-search-btn');
        if (search_btn) {
            search_btn.addEventListener('click', function() {
                var mode = document.querySelector('input[name="search_mode"]:checked').value;
                var params = { _mode: mode };

                if (mode === 'outbound') {
                    params._message_id = document.getElementById('elasticlogs-message-id').value;
                } else {
                    params._sender = document.getElementById('elasticlogs-sender').value;
                    params._date_from = document.getElementById('elasticlogs-date-from').value;
                    params._date_to = document.getElementById('elasticlogs-date-to').value;
                }

                rcmail.http_post('search', params);
            });
        }

        // Handle search response
        rcmail.addEventListener('plugin.elasticlogs_search_response', function(response) {
            var results_list = document.getElementById('elasticlogs-results-list');
            var no_results = document.getElementById('elasticlogs-no-results');

            results_list.innerHTML = '';

            if (!response.results || response.results.length === 0) {
                no_results.style.display = '';
            } else {
                no_results.style.display = 'none';
                response.results.forEach(function(entry) {
                    var div = document.createElement('div');
                    div.className = 'elasticlogs-log-entry';
                    div.textContent = entry['@timestamp'] + ' ' + entry.message;
                    results_list.appendChild(div);
                });
            }
        });
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
