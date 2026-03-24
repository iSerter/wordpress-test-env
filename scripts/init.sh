#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Full setup: build, start, install WordPress + WooCommerce, seed data."
    echo "  Examples: $0              # setup all instances"
    echo "            $0 8.3 6.8      # setup only PHP 8.3 + WP 6.8"
    exit 0
fi

parse_filter_args "$@"
cd "$PROJECT_DIR"

# ── 1. Environment file ────────────────────────────────────────
if [[ ! -f .env ]]; then
    log_info "Creating .env from .env.example..."
    cp .env.example .env
fi

# ── 2. Build and start ─────────────────────────────────────────
if [[ -n "$FILTER_PHP" && -n "$FILTER_WP" ]]; then
    local_svc=$(svc_name "$FILTER_PHP" "$FILTER_WP")
    log_info "Building and starting $local_svc..."
    docker compose up -d --build db "$local_svc"
else
    log_info "Building and starting all containers (this may take a while on first run)..."
    docker compose up -d --build
fi

# ── 3. Wait for database ───────────────────────────────────────
log_info "Waiting for database..."
attempts=0
until docker compose exec -T db healthcheck.sh --connect --innodb_initialized &>/dev/null; do
    attempts=$((attempts + 1))
    if [[ $attempts -ge 30 ]]; then
        log_error "Database not ready after 60s"
        exit 1
    fi
    sleep 2
done
log_success "Database ready."

# ── 4. Setup WordPress ─────────────────────────────────────────
echo ""
"$PROJECT_DIR/scripts/setup-wordpress.sh" ${FILTER_PHP:+"$FILTER_PHP"} ${FILTER_WP:+"$FILTER_WP"}

# ── 5. Install WooCommerce ─────────────────────────────────────
echo ""
"$PROJECT_DIR/scripts/install-woocommerce.sh" ${FILTER_PHP:+"$FILTER_PHP"} ${FILTER_WP:+"$FILTER_WP"}

# ── 6. Seed dummy data ─────────────────────────────────────────
echo ""
"$PROJECT_DIR/scripts/seed-data.sh" ${FILTER_PHP:+"$FILTER_PHP"} ${FILTER_WP:+"$FILTER_WP"}

# ── 7. Summary ──────────────────────────────────────────────────
echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
"$PROJECT_DIR/scripts/status.sh"
