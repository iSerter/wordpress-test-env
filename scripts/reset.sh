#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Tear down containers AND delete volumes (full reset)."
    echo "  Single-instance reset drops the DB and removes the WP volume."
    echo "  Full reset removes everything including the shared DB."
    echo "  Examples: $0              # reset everything"
    echo "            $0 8.3 6.8      # reset only PHP 8.3 + WP 6.8"
    exit 0
fi

parse_filter_args "$@"
cd "$PROJECT_DIR"

if [[ -n "$FILTER_PHP" && -n "$FILTER_WP" ]]; then
    local_svc=$(svc_name "$FILTER_PHP" "$FILTER_WP")
    local_db=$(db_name "$FILTER_PHP" "$FILTER_WP")

    log_warn "This will destroy all data for $local_svc."
    read -rp "Continue? [y/N] " confirm
    [[ "$confirm" == [yY] ]] || { echo "Aborted."; exit 0; }

    docker compose stop "$local_svc" 2>/dev/null || true
    docker compose rm -f "$local_svc" 2>/dev/null || true
    docker volume rm "wp-test-env_${local_svc}" 2>/dev/null || true

    # Drop and recreate the database
    docker compose exec -T db mariadb -u root -p"${MYSQL_ROOT_PASSWORD:-rootpassword}" \
        -e "DROP DATABASE IF EXISTS \`${local_db}\`; CREATE DATABASE \`${local_db}\`;" 2>/dev/null || true
else
    log_warn "This will destroy ALL containers and volumes."
    read -rp "Continue? [y/N] " confirm
    [[ "$confirm" == [yY] ]] || { echo "Aborted."; exit 0; }

    docker compose down -v
fi

log_success "Reset complete."
