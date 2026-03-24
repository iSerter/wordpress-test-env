#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Install and activate WooCommerce on all (or one) instance(s)."
    echo "  Examples: $0              # all instances"
    echo "            $0 8.3 6.8      # only PHP 8.3 + WP 6.8"
    exit 0
fi

parse_filter_args "$@"

# WooCommerce version compatible with each WP version.
# Empty = latest. Adjust if the latest is incompatible.
get_wc_version() {
    local wp_v=$1
    case $wp_v in
        6.1|6.2|6.3) echo "7.9.0"  ;;  # WC 8.x requires WP 6.4+
        6.4|6.5)     echo "9.3.0"  ;;  # WC 9.4+ requires WP 6.6+
        *)           echo ""       ;;  # latest
    esac
}

FAILED=0
TOTAL=0

install_instance() {
    local php_v=$1 wp_v=$2
    local svc wc_version
    svc=$(svc_name "$php_v" "$wp_v")
    wc_version=$(get_wc_version "$wp_v")
    TOTAL=$((TOTAL + 1))

    if wp_exec "$svc" plugin is-active woocommerce &>/dev/null; then
        log_success "$svc — WooCommerce already active, skipping"
        return 0
    fi

    log_info "$svc — installing WooCommerce${wc_version:+ $wc_version}..."

    local install_args=(woocommerce --activate)
    [[ -n "$wc_version" ]] && install_args+=(--version="$wc_version")

    if ! wp_exec "$svc" plugin install "${install_args[@]}"; then
        log_error "$svc — WooCommerce installation failed"
        FAILED=$((FAILED + 1))
        return 0
    fi

    # Basic store settings
    wp_exec "$svc" option update woocommerce_store_address "123 Test Street" 2>/dev/null || true
    wp_exec "$svc" option update woocommerce_store_city "San Francisco" 2>/dev/null || true
    wp_exec "$svc" option update woocommerce_default_country "US:CA" 2>/dev/null || true
    wp_exec "$svc" option update woocommerce_store_postcode "94103" 2>/dev/null || true
    wp_exec "$svc" option update woocommerce_currency "USD" 2>/dev/null || true
    wp_exec "$svc" option update woocommerce_calc_taxes "yes" 2>/dev/null || true

    # Enable Cash on Delivery for testing
    wp_exec "$svc" option update woocommerce_cod_settings \
        '{"enabled":"yes","title":"Cash on Delivery","description":"Pay on delivery","instructions":"Pay on delivery"}' \
        --format=json 2>/dev/null || true

    # Skip setup wizard
    wp_exec "$svc" option update woocommerce_onboarding_profile '{"completed":true}' --format=json 2>/dev/null || true
    wp_exec "$svc" option update woocommerce_task_list_hidden "yes" 2>/dev/null || true

    # Create WooCommerce pages
    wp_exec "$svc" wc --user="$WP_ADMIN_USER" tool run install_pages 2>/dev/null || true

    log_success "$svc — WooCommerce installed and configured"
}

log_info "Installing WooCommerce..."
echo ""
for_each_instance install_instance "$FILTER_PHP" "$FILTER_WP"

echo ""
if [[ $FAILED -eq 0 ]]; then
    log_success "WooCommerce installed on all $TOTAL instance(s)."
else
    log_warn "$FAILED of $TOTAL instance(s) failed."
fi
