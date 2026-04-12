#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

FOLLOW=false
TAIL=100
POSITIONAL=()

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version] [--follow] [--tail N]"
    echo "  View Docker container logs."
    echo "  Examples: $0                       # last 100 lines, all instances"
    echo "            $0 8.3 6.8               # last 100 lines, one instance"
    echo "            $0 8.3 6.8 --follow      # stream live logs"
    echo "            $0 --tail 50             # last 50 lines"
    exit 0
fi

SKIP_NEXT=false
for i in $(seq 1 $#); do
    arg="${!i}"
    if [[ "$SKIP_NEXT" == true ]]; then
        SKIP_NEXT=false
        continue
    fi
    case $arg in
        --follow|-f) FOLLOW=true ;;
        --tail)
            next=$((i + 1))
            TAIL="${!next}"
            SKIP_NEXT=true
            ;;
        *) POSITIONAL+=("$arg") ;;
    esac
done

cd "$PROJECT_DIR"

COMPOSE_ARGS=(logs --tail "$TAIL")
[[ "$FOLLOW" == true ]] && COMPOSE_ARGS+=(--follow)

if [[ ${#POSITIONAL[@]} -ge 2 ]]; then
    php_v="${POSITIONAL[0]}"
    wp_v="${POSITIONAL[1]}"
    if ! is_valid_combo "$php_v" "$wp_v"; then
        log_error "Invalid combination: PHP $php_v + WP $wp_v"
        exit 1
    fi
    svc=$(svc_name "$php_v" "$wp_v")
    docker compose "${COMPOSE_ARGS[@]}" "$svc"
else
    docker compose "${COMPOSE_ARGS[@]}"
fi
