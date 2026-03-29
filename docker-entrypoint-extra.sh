#!/bin/bash
set -e

# Start the cron daemon in the background
cron

# Pass DISABLE_WP_CRON into wp-config.php so WordPress uses system cron
# instead of its built-in pseudo-cron on every page load
if [ "$DISABLE_WP_CRON" = "true" ]; then
    export WORDPRESS_CONFIG_EXTRA="define('DISABLE_WP_CRON', true);"
fi

# Hand off to the original WordPress entrypoint.
# We pass apache2-custom-foreground as the command (instead of
# apache2-foreground directly) so that AFTER the WP entrypoint
# finishes its file setup, our wrapper fixes wp-content ownership
# before starting Apache. The "apache2" prefix in the script name
# ensures the WP entrypoint recognises it and runs its setup logic.
exec docker-entrypoint.sh apache2-custom-foreground
