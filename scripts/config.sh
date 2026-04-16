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
    # Rule 1: combo must exist as an official Docker image.
    [[ " $(get_valid_php "$wp_v") " == *" $php_v "* ]] || return 1
    # Rule 2: if wp-test-env.yml declares a matrix, restrict to that subset.
    if [[ -n "${MATRIX_CONSTRAINT:-}" ]]; then
        [[ " $MATRIX_CONSTRAINT " == *" $php_v:$wp_v "* ]] || return 1
    fi
    return 0
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

# ── Plugin bind-mounts (opt-in) ─────────────────────────────────
# PLUGIN_PATHS is a comma-separated list of directories to bind-mount
# into every WP service at /var/www/html/wp-content/plugins/<basename>.
# Paths may be absolute or relative to PROJECT_DIR. Empty = disabled,
# preserving pre-0.2.0 behavior exactly.

# Portable realpath: GNU realpath → python3 → pure-bash cd+pwd fallback.
_abspath() {
    if command -v realpath >/dev/null 2>&1; then
        realpath "$1" 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
    else
        local d b
        d=$(cd "$(dirname "$1")" 2>/dev/null && pwd) || return 1
        b=$(basename "$1")
        [[ "$b" == "." ]] && { echo "$d"; return 0; }
        echo "$d/$b"
    fi
}

PLUGIN_MOUNT_PATHS=()
PLUGIN_MOUNT_NAMES=()
parse_plugin_paths() {
    PLUGIN_MOUNT_PATHS=()
    PLUGIN_MOUNT_NAMES=()
    [[ -z "${PLUGIN_PATHS:-}" ]] && return 0
    local IFS=','
    local raw path abs
    for raw in $PLUGIN_PATHS; do
        # trim leading/trailing whitespace
        path="${raw#"${raw%%[![:space:]]*}"}"
        path="${path%"${path##*[![:space:]]}"}"
        [[ -z "$path" ]] && continue
        # Resolve relative paths against PROJECT_DIR
        if [[ "$path" != /* ]]; then
            path="$PROJECT_DIR/$path"
        fi
        abs=$(_abspath "$path") || { log_error "PLUGIN_PATHS entry not found: $path"; exit 1; }
        if [[ ! -d "$abs" ]]; then
            log_error "PLUGIN_PATHS entry is not a directory: $abs"
            exit 1
        fi
        PLUGIN_MOUNT_PATHS+=("$abs")
        PLUGIN_MOUNT_NAMES+=("$(basename "$abs")")
    done
}

# Load wp-test-env.yml (if present) AFTER .env but BEFORE parse_plugin_paths,
# so yml-declared plugins flow through to the bind-mount machinery.
# shellcheck disable=SC1091
if [[ -f "$PROJECT_DIR/scripts/lib/load-config.sh" ]]; then
    source "$PROJECT_DIR/scripts/lib/load-config.sh"
fi

parse_plugin_paths
