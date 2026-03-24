#!/bin/bash
set -e

# Start the cron daemon in the background
cron

# Pass DISABLE_WP_CRON into wp-config.php so WordPress uses system cron
# instead of its built-in pseudo-cron on every page load
if [ "$DISABLE_WP_CRON" = "true" ]; then
    export WORDPRESS_CONFIG_EXTRA="define('DISABLE_WP_CRON', true);"
fi

# Hand off to the original WordPress entrypoint
exec docker-entrypoint.sh "$@"
