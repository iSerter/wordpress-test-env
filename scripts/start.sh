#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Start all (or one) WordPress instance(s)."
    echo "  The shared DB is always started."
    echo "  Examples: $0              # start all"
    echo "            $0 8.3 6.8      # start only PHP 8.3 + WP 6.8"
    exit 0
fi

parse_filter_args "$@"
cd "$PROJECT_DIR"

if [[ -n "$FILTER_PHP" && -n "$FILTER_WP" ]]; then
    local_svc=$(svc_name "$FILTER_PHP" "$FILTER_WP")
    log_info "Starting $local_svc..."
    docker compose up -d db "$local_svc"
else
    log_info "Starting all instances..."
    docker compose up -d
fi

echo ""
exec "$PROJECT_DIR/scripts/status.sh"
