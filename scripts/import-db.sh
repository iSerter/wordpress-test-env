#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" || $# -lt 2 ]]; then
    echo "Usage: $0 <php_version> <wp_version> [sql_file]"
    echo "  Import a SQL file into a WordPress instance's database."
    echo "  If no file specified, uses snapshots/wp_{php}_{wp}.sql"
    echo "  Examples: $0 8.3 6.8                              # uses default snapshot"
    echo "            $0 8.3 6.8 snapshots/wp_83_68.sql       # explicit file"
    exit 0
fi

php_v="$1"
wp_v="$2"
SQL_FILE="${3:-}"

if ! is_valid_combo "$php_v" "$wp_v"; then
    log_error "Invalid combination: PHP $php_v + WP $wp_v"
    exit 1
fi

svc=$(svc_name "$php_v" "$wp_v")
db=$(db_name "$php_v" "$wp_v")

cd "$PROJECT_DIR"

if [[ -z "$SQL_FILE" ]]; then
    SQL_FILE="snapshots/${db}.sql"
fi

if [[ ! -f "$SQL_FILE" ]]; then
    log_error "File not found: $SQL_FILE"
    exit 1
fi

log_warn "This will overwrite the database for $svc."
read -rp "Continue? [y/N] " confirm
[[ "$confirm" == [yY] ]] || { echo "Aborted."; exit 0; }

log_info "Importing $SQL_FILE into $svc..."
docker cp "$SQL_FILE" "${svc}:/tmp/import.sql"
wp_exec "$svc" db import /tmp/import.sql
log_success "Import complete."
