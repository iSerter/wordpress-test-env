#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Seed dummy data (products, orders, customers, coupons)."
    echo "  Examples: $0              # all instances"
    echo "            $0 8.3 6.8      # only PHP 8.3 + WP 6.8"
    exit 0
fi

parse_filter_args "$@"

FAILED=0
TOTAL=0

seed_instance() {
    local php_v=$1 wp_v=$2
    local svc
    svc=$(svc_name "$php_v" "$wp_v")
    TOTAL=$((TOTAL + 1))

    if ! wp_exec "$svc" plugin is-active woocommerce &>/dev/null; then
        log_error "$svc — WooCommerce not active, skipping"
        FAILED=$((FAILED + 1))
        return 0
    fi

    # Import WooCommerce sample products
    local sample_xml="/var/www/html/wp-content/plugins/woocommerce/sample-data/sample_products.xml"
    local product_count
    product_count=$(wp_exec "$svc" post list --post_type=product --format=count 2>/dev/null || echo "0")

    if [[ "$product_count" -gt 0 ]]; then
        log_info "$svc — $product_count products exist, skipping import"
    else
        log_info "$svc — importing WooCommerce sample products..."
        wp_exec "$svc" plugin install wordpress-importer --activate 2>/dev/null || true
        if wp_exec "$svc" import "$sample_xml" --authors=skip 2>/dev/null; then
            log_success "$svc — sample products imported"
        else
            log_warn "$svc — product import failed (sample file may not exist in this WC version)"
        fi
    fi

    # Seed customers, orders, coupons
    log_info "$svc — seeding customers, orders, coupons..."
    if docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T "$svc" \
        wp eval-file - < "$SCRIPT_DIR/data/seed-extra.php"; then
        log_success "$svc — seed data created"
    else
        log_warn "$svc — some seed data may have failed"
    fi
}

log_info "Seeding dummy data..."
echo ""
for_each_instance seed_instance "$FILTER_PHP" "$FILTER_WP"

echo ""
if [[ $FAILED -eq 0 ]]; then
    log_success "Dummy data seeded on all $TOTAL instance(s)."
else
    log_warn "$FAILED of $TOTAL instance(s) had issues."
fi
