#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0"
    echo "  Show status of all WordPress test instances."
    exit 0
fi

cd "$PROJECT_DIR"

# DB status
db_state=$(docker inspect --format='{{.State.Status}}' wp-test-db 2>/dev/null || echo "not found")
if [[ "$db_state" == "running" ]]; then
    db_display="${GREEN}running${NC}"
else
    db_display="${RED}${db_state}${NC}"
fi
echo ""
echo -e "Database (MariaDB): ${db_display}"
echo ""

# Header
printf "%-14s  %-6s  %-6s  %-6s  %-25s  %s\n" "SERVICE" "PHP" "WP" "PORT" "URL" "STATUS"
printf "%-14s  %-6s  %-6s  %-6s  %-25s  %s\n" "───────" "───" "──" "────" "───" "──────"

for php_v in "${PHP_VERSIONS[@]}"; do
    for wp_v in "${WP_VERSIONS[@]}"; do
        svc=$(svc_name "$php_v" "$wp_v")
        port=$(get_port "$php_v" "$wp_v")
        url="http://localhost:${port}"

        state=$(docker inspect --format='{{.State.Status}}' "$svc" 2>/dev/null || echo "–")
        if [[ "$state" == "running" ]]; then
            display="${GREEN}running${NC}"
        elif [[ "$state" == "–" ]]; then
            display="–"
        else
            display="${RED}${state}${NC}"
        fi

        printf "%-14s  %-6s  %-6s  %-6s  %-25s  " "$svc" "$php_v" "$wp_v" "$port" "$url"
        echo -e "$display"
    done
done

echo ""
printf "Admin: %s / %s\n" "$WP_ADMIN_USER" "$WP_ADMIN_PASSWORD"
echo ""
