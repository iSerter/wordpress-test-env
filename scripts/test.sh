#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

SMOKE_ONLY=false
PW_ARGS=()
POSITIONAL=()

for arg in "$@"; do
    case $arg in
        --help)
            echo "Usage: $0 [php_version wp_version] [--smoke] [-- playwright_args...]"
            echo "  Run Playwright E2E tests against running WordPress instances."
            echo "  Examples: $0                       # all tests, all instances"
            echo "            $0 8.3 6.8               # all tests, one instance"
            echo "            $0 --smoke               # smoke tests only"
            echo "            $0 -- --headed           # pass args to Playwright"
            exit 0
            ;;
        --smoke) SMOKE_ONLY=true ;;
        --)      shift; PW_ARGS+=("$@"); break ;;
        *)       POSITIONAL+=("$arg") ;;
    esac
done

cd "$PROJECT_DIR"

# ── 1. Ensure dependencies ────────────────────────────────────
if [[ ! -d node_modules ]]; then
    log_info "Installing npm dependencies..."
    npm install
fi

if ! npx playwright --version &>/dev/null; then
    log_info "Installing Playwright browsers..."
    npx playwright install --with-deps chromium
fi

# ── 2. Determine target instances ─────────────────────────────
if [[ ${#POSITIONAL[@]} -ge 2 ]]; then
    php_v="${POSITIONAL[0]}"
    wp_v="${POSITIONAL[1]}"

    if ! is_valid_combo "$php_v" "$wp_v"; then
        log_error "Invalid combination: PHP $php_v + WP $wp_v"
        exit 1
    fi

    PROJECT_FLAG="--project=php${php_v}-wp${wp_v}"
    PW_ARGS=("$PROJECT_FLAG" "${PW_ARGS[@]}")
fi

# ── 3. Set test path ──────────────────────────────────────────
if [[ "$SMOKE_ONLY" == true ]]; then
    PW_ARGS+=("tests/e2e/specs/smoke/")
fi

# ── 4. Run tests ──────────────────────────────────────────────
log_info "Running Playwright tests..."
echo ""
npx playwright test "${PW_ARGS[@]}"
