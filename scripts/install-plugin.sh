#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" || $# -lt 1 ]]; then
    echo "Usage: $0 <slug-or-zip> [php_version wp_version]"
    echo "  Install a WordPress plugin from a slug or zip file."
    echo "  Examples: $0 query-monitor               # slug, all instances"
    echo "            $0 query-monitor 8.3 6.8        # slug, one instance"
    echo "            $0 ./my-plugin.zip              # zip, all instances"
    echo "            $0 ./my-plugin.zip 8.3 6.8      # zip, one instance"
    exit 0
fi

PLUGIN_SOURCE="$1"; shift
FILTER_PHP=""
FILTER_WP=""
if [[ $# -ge 2 ]]; then
    FILTER_PHP="$1"
    FILTER_WP="$2"
fi

IS_ZIP=false
if [[ "$PLUGIN_SOURCE" == *.zip ]] || [[ "$PLUGIN_SOURCE" == */* && -f "$PLUGIN_SOURCE" ]]; then
    IS_ZIP=true
    if [[ ! -f "$PLUGIN_SOURCE" ]]; then
        log_error "File not found: $PLUGIN_SOURCE"
        exit 1
    fi
    PLUGIN_SOURCE=$(cd "$(dirname "$PLUGIN_SOURCE")" && pwd)/$(basename "$PLUGIN_SOURCE")
fi

install_on_instance() {
    local php_v=$1 wp_v=$2
    local svc
    svc=$(svc_name "$php_v" "$wp_v")

    # Skip instances that aren't running
    state=$(docker inspect --format='{{.State.Status}}' "$svc" 2>/dev/null || echo "–")
    if [[ "$state" != "running" ]]; then
        log_warn "$svc is not running, skipping."
        return
    fi

    if [[ "$IS_ZIP" == true ]]; then
        local dest="/tmp/$(basename "$PLUGIN_SOURCE")"
        log_info "$svc: Copying $(basename "$PLUGIN_SOURCE")..."
        docker cp "$PLUGIN_SOURCE" "${svc}:${dest}"
        wp_exec "$svc" plugin install "$dest" --activate --force 2>/dev/null \
            && log_success "$svc: Installed and activated." \
            || log_error "$svc: Installation failed."
    else
        log_info "$svc: Installing $PLUGIN_SOURCE..."
        wp_exec "$svc" plugin install "$PLUGIN_SOURCE" --activate --force 2>/dev/null \
            && log_success "$svc: Installed and activated." \
            || log_error "$svc: Installation failed."
    fi
}

cd "$PROJECT_DIR"
for_each_instance install_on_instance "$FILTER_PHP" "$FILTER_WP"
