#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Stop all (or one) WordPress instance(s). Volumes are preserved."
    echo "  When stopping a single instance, the shared DB stays running."
    echo "  Examples: $0              # stop all (including DB)"
    echo "            $0 8.3 6.8      # stop only PHP 8.3 + WP 6.8"
    exit 0
fi

parse_filter_args "$@"
cd "$PROJECT_DIR"

if [[ -n "$FILTER_PHP" && -n "$FILTER_WP" ]]; then
    local_svc=$(svc_name "$FILTER_PHP" "$FILTER_WP")
    log_info "Stopping $local_svc..."
    docker compose stop "$local_svc"
else
    log_info "Stopping all instances..."
    docker compose down
fi

log_success "Done."
