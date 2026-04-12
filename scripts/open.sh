#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

FRONT=false
POSITIONAL=()

for arg in "$@"; do
    case $arg in
        --help)
            echo "Usage: $0 <php_version> <wp_version> [--front]"
            echo "  Open a WordPress instance in the default browser."
            echo "  Examples: $0 8.3 6.8            # opens wp-admin"
            echo "            $0 8.3 6.8 --front    # opens the frontend"
            exit 0
            ;;
        --front) FRONT=true ;;
        *)       POSITIONAL+=("$arg") ;;
    esac
done

if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
    log_error "Specify both PHP and WP versions, e.g.: $0 8.3 6.8"
    exit 1
fi

php_v="${POSITIONAL[0]}"
wp_v="${POSITIONAL[1]}"

if ! is_valid_combo "$php_v" "$wp_v"; then
    log_error "Invalid combination: PHP $php_v + WP $wp_v"
    exit 1
fi

port=$(get_port "$php_v" "$wp_v")

if [[ "$FRONT" == true ]]; then
    url="http://localhost:${port}"
else
    url="http://localhost:${port}/wp-admin"
fi

log_info "Opening $url ..."

if command -v open &>/dev/null; then
    open "$url"
elif command -v xdg-open &>/dev/null; then
    xdg-open "$url"
else
    log_warn "No browser opener found. Visit: $url"
fi
