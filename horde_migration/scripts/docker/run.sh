#!/usr/bin/env bash
# Runs a PHP script inside the local Horde export container, with the
# /srv/www/mail-profissional layout reconstructed from the local
# webmail-horde checkout (source + install + config), a secret-free conf.php
# override shadowing the real one, and --network host so the read-only DB
# connection keeps using this machine's already-trusted IP.
#
# Usage: run.sh <script-path-relative-to-scripts-dir> [args...]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="$(dirname "$SCRIPT_DIR")"          # horde_migration/scripts
MIGRATION_ROOT="$(dirname "$SCRIPTS_ROOT")"       # horde_migration
HORDE_ROOT="/home/sergio/Projects/Sooma/Profissional/webmail-horde"
IMAGE=horde-export-cli

docker build -q -t "$IMAGE" "$SCRIPT_DIR" >/dev/null

exec docker run --rm -i \
    --network host \
    -v "$HORDE_ROOT/source:/srv/www/mail-profissional/source:ro" \
    -v "$HORDE_ROOT/install:/srv/www/mail-profissional/install:ro" \
    -v "$HORDE_ROOT/config:/srv/www/mail-profissional/config:ro" \
    -v "$SCRIPTS_ROOT/config-override/horde/config/conf.php:/srv/www/mail-profissional/config/horde/config/conf.php:ro" \
    -v "$SCRIPTS_ROOT/config-override/horde/config/hooks.php:/srv/www/mail-profissional/config/horde/config/hooks.php:ro" \
    -v "$SCRIPTS_ROOT/config-override/kronolith-lib-Driver-Sql.php:/srv/www/mail-profissional/source/kronolith/lib/Driver/Sql.php:ro" \
    -v "$SCRIPTS_ROOT:/work:ro" \
    -v "$MIGRATION_ROOT/export-output:/output:rw" \
    "$IMAGE" \
    sh -c 'script=$1; shift; mkdir -p /tmp/horde-export/vfs && exec php /work/"$script" "$@"' -- "$@"
