#!/usr/bin/env bash
# Shared configuration for all scripts

# ── Version matrix ──────────────────────────────────────────────
# Based on Docker Hub: https://hub.docker.com/_/wordpress/tags
# Last verified: 2026-03-24
# WP 7.0 is still in beta — add it here when stable images are published.
WP_VERSIONS=(6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 7.0)
PHP_VERSIONS=(8.1 8.2 8.3 8.4 8.5)

# Valid PHP versions for each WP release (maps to Docker Hub tags)
get_valid_php() {
    case $1 in
        6.1|6.2|6.3)  echo "8.1 8.2" ;;
        6.4|6.5|6.6)  echo "8.1 8.2 8.3" ;;
        6.7)           echo "8.1 8.2 8.3 8.4" ;;
        6.8|6.9)       echo "8.1 8.2 8.3 8.4 8.5" ;;
        7.0)           echo "8.2 8.3 8.4 8.5" ;;
        *)             echo "" ;;
    esac
}

# Docker Hub image tag for a PHP+WP combination
get_docker_tag() {
    local php_v=$1 wp_v=$2
    case $wp_v in
        7.0) echo "wordpress:beta-${wp_v}-php${php_v}-apache" ;;
        *)   echo "wordpress:${wp_v}-php${php_v}-apache" ;;
    esac
}

is_valid_combo() {
    local php_v=$1 wp_v=$2
    [[ " $(get_valid_php "$wp_v") " == *" $php_v "* ]]
}

# ── Helpers ─────────────────────────────────────────────────────
slug()     { echo "${1//./}"; }                                    # "8.1" → "81"
svc_name() { echo "wp-$(slug "$1")-$(slug "$2")"; }               # "wp-81-61"
get_port() { echo "$(slug "$1")$(slug "$2")"; }                    # "8161"
db_name()  { echo "wp_$(slug "$1")_$(slug "$2")"; }               # "wp_81_61"

# ── Project root ────────────────────────────────────────────────
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Load .env ───────────────────────────────────────────────────
if [[ -f "$PROJECT_DIR/.env" ]]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# ── Defaults ────────────────────────────────────────────────────
WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-admin}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
WP_SITE_TITLE="${WP_SITE_TITLE:-WP Test}"

# ── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERR ]${NC} $*"; }

# ── Docker helpers ──────────────────────────────────────────────
wp_exec() {
    local service=$1; shift
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T --user www-data "$service" wp "$@"
}

wait_for_wp() {
    local service=$1
    local max_attempts=${2:-30}
    local attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T "$service" \
            php -r '$c = @new mysqli(getenv("WORDPRESS_DB_HOST"), getenv("WORDPRESS_DB_USER"), getenv("WORDPRESS_DB_PASSWORD"), getenv("WORDPRESS_DB_NAME")); if($c->connect_error) exit(1);' \
            &>/dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    return 1
}

# ── Iteration ───────────────────────────────────────────────────
# Call: for_each_instance callback [php_ver wp_ver]
# With no filter → all valid combos. With both → single combo.
for_each_instance() {
    local callback=$1
    local filter_php=${2:-}
    local filter_wp=${3:-}

    local php_list=("${PHP_VERSIONS[@]}")
    local wp_list=("${WP_VERSIONS[@]}")

    [[ -n "$filter_php" ]] && php_list=("$filter_php")
    [[ -n "$filter_wp" ]]  && wp_list=("$filter_wp")

    for php_v in "${php_list[@]}"; do
        for wp_v in "${wp_list[@]}"; do
            is_valid_combo "$php_v" "$wp_v" || continue
            "$callback" "$php_v" "$wp_v"
        done
    done
}

# ── Argument parsing ────────────────────────────────────────────
# Scripts accept: no args (all), or: PHP_VER WP_VER (specific combo)
parse_filter_args() {
    FILTER_PHP=""
    FILTER_WP=""
    if [[ $# -ge 2 ]]; then
        FILTER_PHP="$1"
        FILTER_WP="$2"
    elif [[ $# -eq 1 && "$1" != "--help" ]]; then
        echo "Error: specify both PHP and WP versions, e.g.: $0 8.3 6.8"
        exit 1
    fi
}
