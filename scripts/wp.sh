#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" || $# -lt 3 ]]; then
    echo "Usage: $0 <php_version> <wp_version> <wp-cli command...>"
    echo "  Run an arbitrary WP-CLI command inside a container."
    echo "  Examples: $0 8.3 6.8 plugin list"
    echo "            $0 8.3 6.8 option get siteurl"
    echo "            $0 8.3 6.8 db query \"SELECT count(*) FROM wp_posts\""
    exit 0
fi

php_v="$1"; shift
wp_v="$1"; shift

if ! is_valid_combo "$php_v" "$wp_v"; then
    log_error "Invalid combination: PHP $php_v + WP $wp_v"
    exit 1
fi

svc=$(svc_name "$php_v" "$wp_v")
wp_exec "$svc" "$@"
