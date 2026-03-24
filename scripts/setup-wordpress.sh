#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Install and configure WordPress on all (or one) instance(s)."
    echo "  Examples: $0              # all 50 instances"
    echo "            $0 8.3 6.8      # only PHP 8.3 + WP 6.8"
    exit 0
fi

parse_filter_args "$@"

FAILED=0
TOTAL=0

setup_instance() {
    local php_v=$1 wp_v=$2
    local svc port
    svc=$(svc_name "$php_v" "$wp_v")
    port=$(get_port "$php_v" "$wp_v")
    TOTAL=$((TOTAL + 1))

    log_info "$svc — waiting for database..."
    if ! wait_for_wp "$svc" 60; then
        log_error "$svc — database not ready after 120s, skipping"
        FAILED=$((FAILED + 1))
        return 0
    fi

    if wp_exec "$svc" core is-installed &>/dev/null; then
        log_success "$svc — already installed, skipping"
        return 0
    fi

    log_info "$svc — running core install..."
    wp_exec "$svc" core install \
        --url="http://localhost:${port}" \
        --title="${WP_SITE_TITLE} ${wp_v} (PHP ${php_v})" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    wp_exec "$svc" rewrite structure '/%postname%/'
    wp_exec "$svc" option update timezone_string "UTC"
    wp_exec "$svc" option update blog_public 0

    wp_exec "$svc" config set WP_AUTO_UPDATE_CORE false --raw --type=constant 2>/dev/null || true
    wp_exec "$svc" config set AUTOMATIC_UPDATER_DISABLED true --raw --type=constant 2>/dev/null || true

    log_success "$svc — installed at http://localhost:${port}"
}

log_info "Setting up WordPress instances..."
echo ""
for_each_instance setup_instance "$FILTER_PHP" "$FILTER_WP"

echo ""
if [[ $FAILED -eq 0 ]]; then
    log_success "All $TOTAL instance(s) configured successfully."
else
    log_warn "$FAILED of $TOTAL instance(s) failed."
fi
