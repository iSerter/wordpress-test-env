#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# ── Generate docker-compose.yml ─────────────────────────────────
COMPOSE="$PROJECT_DIR/docker-compose.yml"
INIT_SQL="$PROJECT_DIR/db/init.sql"

mkdir -p "$PROJECT_DIR/db"

log_info "Generating docker-compose.yml (${#PHP_VERSIONS[@]} PHP versions × ${#WP_VERSIONS[@]} WP versions, valid combos only)..."

cat > "$COMPOSE" <<'HEADER'
# ╔════════════════════════════════════════════════════════════════╗
# ║  AUTO-GENERATED — do not edit by hand.                        ║
# ║  Re-generate: ./scripts/generate-compose.sh                   ║
# ╚════════════════════════════════════════════════════════════════╝
#
# WordPress Multi-Version + Multi-PHP Test Environment
# Port scheme: {php_major}{php_minor}{wp_major}{wp_minor}
#   e.g. PHP 8.3 + WP 6.8 → port 8368

name: wp-test-env

services:

  # ── Shared Database ────────────────────────────────────────────
  db:
    image: mariadb:10.11
    container_name: wp-test-db
    restart: unless-stopped
    networks:
      - wp-test-net
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-rootpassword}
      MYSQL_USER: ${MYSQL_USER:-wordpress}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-wordpress}
    volumes:
      - db-data:/var/lib/mysql
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5
HEADER

# ── WordPress services ──────────────────────────────────────────
svc_count=0
for php_v in "${PHP_VERSIONS[@]}"; do
    for wp_v in "${WP_VERSIONS[@]}"; do
        is_valid_combo "$php_v" "$wp_v" || continue
        svc_count=$((svc_count + 1))
        svc=$(svc_name "$php_v" "$wp_v")
        port=$(get_port "$php_v" "$wp_v")
        db=$(db_name "$php_v" "$wp_v")
        img=$(get_docker_tag "$php_v" "$wp_v")

        cat >> "$COMPOSE" <<EOF

  # ── PHP ${php_v} + WP ${wp_v} ─────────────────────────────────
  ${svc}:
    build:
      context: .
      args:
        BASE_IMAGE: "${img}"
    container_name: ${svc}
    ports:
      - "${port}:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: ${db}
      WORDPRESS_DB_USER: \${MYSQL_USER:-wordpress}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD:-wordpress}
      WORDPRESS_DEBUG: "1"
    volumes:
      - ${svc}:/var/www/html
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - wp-test-net
EOF
    done
done

# ── Volumes ─────────────────────────────────────────────────────
{
    echo ""
    echo "volumes:"
    echo "  db-data:"
    for php_v in "${PHP_VERSIONS[@]}"; do
        for wp_v in "${WP_VERSIONS[@]}"; do
            is_valid_combo "$php_v" "$wp_v" || continue
            echo "  $(svc_name "$php_v" "$wp_v"):"
        done
    done

    echo ""
    echo "networks:"
    echo "  wp-test-net:"
    echo "    driver: bridge"
} >> "$COMPOSE"

# ── Generate db/init.sql ────────────────────────────────────────
log_info "Generating db/init.sql..."

cat > "$INIT_SQL" <<'HEADER'
-- ╔════════════════════════════════════════════════════════════════╗
-- ║  AUTO-GENERATED — do not edit by hand.                        ║
-- ║  Re-generate: ./scripts/generate-compose.sh                   ║
-- ╚════════════════════════════════════════════════════════════════╝

HEADER

for php_v in "${PHP_VERSIONS[@]}"; do
    for wp_v in "${WP_VERSIONS[@]}"; do
        is_valid_combo "$php_v" "$wp_v" || continue
        echo "CREATE DATABASE IF NOT EXISTS \`$(db_name "$php_v" "$wp_v")\`;" >> "$INIT_SQL"
    done
done

cat >> "$INIT_SQL" <<'FOOTER'

-- Grant the wordpress user access to all wp_* databases
GRANT ALL PRIVILEGES ON `wp_%`.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;
FOOTER

# ── Summary ─────────────────────────────────────────────────────
log_success "Generated ${svc_count} WordPress services + 1 DB service"
log_success "  → $COMPOSE"
log_success "  → $INIT_SQL"
