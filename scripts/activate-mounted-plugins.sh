#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Activate every plugin declared in PLUGIN_PATHS on running instances."
    echo "  Examples: $0             # all running instances"
    echo "            $0 8.3 6.8     # one instance"
    exit 0
fi

parse_filter_args "$@"

if [[ ${#PLUGIN_MOUNT_NAMES[@]} -eq 0 ]]; then
    log_warn "PLUGIN_PATHS is empty — nothing to activate."
    exit 0
fi

activate_on_instance() {
    local php_v=$1 wp_v=$2
    local svc
    svc=$(svc_name "$php_v" "$wp_v")

    local state
    state=$(docker inspect --format='{{.State.Status}}' "$svc" 2>/dev/null || echo "-")
    if [[ "$state" != "running" ]]; then
        log_warn "$svc is not running, skipping."
        return
    fi

    for name in "${PLUGIN_MOUNT_NAMES[@]}"; do
        if wp_exec "$svc" plugin activate "$name" 2>/dev/null; then
            log_success "$svc: activated $name"
        else
            log_error "$svc: failed to activate $name"
        fi
    done
}

cd "$PROJECT_DIR"
for_each_instance activate_on_instance "$FILTER_PHP" "$FILTER_WP"
