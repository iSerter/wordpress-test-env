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
