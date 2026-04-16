#!/usr/bin/env bash
# Golden-file test: verify that generate-compose.sh with PLUGIN_PATHS unset
# produces byte-identical output to tests/fixtures/docker-compose.golden.yml.
#
# This guards the backward-compatibility promise in the v0.2.0 DX task:
# opt-in features must not change the default compose output.
#
# To refresh the golden after an intentional default-behavior change:
#   cp docker-compose.yml tests/fixtures/docker-compose.golden.yml

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GOLDEN="$PROJECT_DIR/tests/fixtures/docker-compose.golden.yml"
ACTUAL="$PROJECT_DIR/docker-compose.yml"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [[ ! -f "$GOLDEN" ]]; then
    echo "[FAIL] Golden fixture missing: $GOLDEN" >&2
    exit 1
fi

# Back up whatever compose file currently exists so the test is non-destructive
[[ -f "$ACTUAL" ]] && cp "$ACTUAL" "$TMP/backup.yml"

# Regenerate with an empty PLUGIN_PATHS env var
(cd "$PROJECT_DIR" && PLUGIN_PATHS="" ./scripts/generate-compose.sh >/dev/null 2>&1)

if diff -u "$GOLDEN" "$ACTUAL" > "$TMP/diff.txt"; then
    [[ -f "$TMP/backup.yml" ]] && cp "$TMP/backup.yml" "$ACTUAL"
    echo "[ OK ] docker-compose.yml matches golden fixture."
    exit 0
else
    [[ -f "$TMP/backup.yml" ]] && cp "$TMP/backup.yml" "$ACTUAL"
    echo "[FAIL] docker-compose.yml differs from golden fixture:" >&2
    cat "$TMP/diff.txt" >&2
    echo "" >&2
    echo "If this change is intentional, refresh the golden:" >&2
    echo "  cp docker-compose.yml tests/fixtures/docker-compose.golden.yml" >&2
    exit 1
fi
