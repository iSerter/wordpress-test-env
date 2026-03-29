ARG BASE_IMAGE=wordpress:6.8-php8.3-apache
FROM ${BASE_IMAGE}

# Install MySQL client tools (needed by WP-CLI db commands) and utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-mysql-client \
    less \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Allow running WP-CLI as root (needed in Docker)
ENV WP_CLI_ALLOW_ROOT=1

# Increase PHP upload limits for plugin/theme uploads
COPY php-uploads.ini /usr/local/etc/php/conf.d/uploads.ini

# Disable WP's built-in PHP cron (runs on every page load, slow + unreliable)
# and use a real system cron instead
ENV DISABLE_WP_CRON=true

# Install cron and set up WP-Cron to run every minute via system cron
RUN apt-get update && apt-get install -y --no-install-recommends cron \
    && rm -rf /var/lib/apt/lists/* \
    && printf '%s\n' \
       '* * * * * www-data cd /var/www/html && /usr/local/bin/wp cron event run --due-now >> /var/log/wp-cron.log 2>&1' \
       '* * * * * www-data cd /var/www/html && /usr/local/bin/wp action-scheduler run >> /var/log/wp-cron.log 2>&1' \
       > /etc/cron.d/wp-cron \
    && chmod 0644 /etc/cron.d/wp-cron

# Wrapper that fixes wp-content permissions after WP entrypoint setup
COPY apache2-custom-foreground /usr/local/bin/
RUN chmod +x /usr/local/bin/apache2-custom-foreground

# Custom entrypoint: start cron daemon alongside Apache
COPY docker-entrypoint-extra.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint-extra.sh
ENTRYPOINT ["docker-entrypoint-extra.sh"]
