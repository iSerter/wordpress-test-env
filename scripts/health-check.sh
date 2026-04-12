#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [php_version wp_version]"
    echo "  Check HTTP health of running WordPress instances."
    echo "  Exits non-zero if any instance fails."
    echo "  Examples: $0              # check all running instances"
    echo "            $0 8.3 6.8      # check one instance"
    exit 0
fi

parse_filter_args "$@"

FAILURES=0
CHECKED=0

check_instance() {
    local php_v=$1 wp_v=$2
    local svc port http_home http_api status_home status_api result

    svc=$(svc_name "$php_v" "$wp_v")
    port=$(get_port "$php_v" "$wp_v")

    # Skip instances that aren't running
    state=$(docker inspect --format='{{.State.Status}}' "$svc" 2>/dev/null || echo "–")
    if [[ "$state" != "running" ]]; then
        return
    fi

    CHECKED=$((CHECKED + 1))

    status_home=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://localhost:${port}/" 2>/dev/null || echo "000")
    status_api=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://localhost:${port}/wp-json/wp/v2/" 2>/dev/null || echo "000")

    if [[ "$status_home" =~ ^(200|301|302)$ ]] && [[ "$status_api" =~ ^(200|301)$ ]]; then
        result="${GREEN}PASS${NC}"
    else
        result="${RED}FAIL${NC}"
        FAILURES=$((FAILURES + 1))
    fi

    printf "  %-14s  PHP %-4s  WP %-4s  home=%-3s  api=%-3s  " "$svc" "$php_v" "$wp_v" "$status_home" "$status_api"
    echo -e "$result"
}

echo ""
log_info "Running health checks..."
echo ""

for_each_instance check_instance "$FILTER_PHP" "$FILTER_WP"

echo ""
if [[ $CHECKED -eq 0 ]]; then
    log_warn "No running instances found."
    exit 1
elif [[ $FAILURES -gt 0 ]]; then
    log_error "$FAILURES of $CHECKED instance(s) failed health check."
    exit 1
else
    log_success "All $CHECKED instance(s) healthy."
fi
