#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" || $# -lt 2 ]]; then
    echo "Usage: $0 <php_version> <wp_version>"
    echo "  Export a WordPress instance's database to a SQL file."
    echo "  Output: snapshots/wp_{php}_{wp}.sql"
    echo "  Example: $0 8.3 6.8    # → snapshots/wp_83_68.sql"
    exit 0
fi

php_v="$1"
wp_v="$2"

if ! is_valid_combo "$php_v" "$wp_v"; then
    log_error "Invalid combination: PHP $php_v + WP $wp_v"
    exit 1
fi

svc=$(svc_name "$php_v" "$wp_v")
db=$(db_name "$php_v" "$wp_v")

cd "$PROJECT_DIR"
mkdir -p snapshots

OUTFILE="snapshots/${db}.sql"

log_info "Exporting $svc database to $OUTFILE..."
wp_exec "$svc" db export - > "$OUTFILE"
log_success "Exported to $OUTFILE ($(du -h "$OUTFILE" | cut -f1))."
