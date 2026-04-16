#!/usr/bin/env bash
# Runs inside the WP container with working dir set to this plugin's folder.
# Used by .github/workflows/integration-example.yml to validate the Action.
set -euo pipefail

echo "--- wp plugin status ---"
wp --allow-root plugin is-active example-plugin-with-tests

echo "--- canary option ---"
canary=$(wp --allow-root option get wp_test_env_action_canary 2>/dev/null || echo "")
if [[ "$canary" != "1" ]]; then
    echo "FAIL: canary option not set (got '$canary')" >&2
    exit 1
fi
echo "PASS: canary option = $canary"

echo "--- PHP version assertion ---"
php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "PHP version inside container: $php_version"
