# Task 09: Audit Docker Hub Image Tags & Fix Version Matrix

**Phase:** 1 - Core Infrastructure (follow-up)
**Status:** Done
**Depends on:** Task 01

## Objective

Review https://hub.docker.com/_/wordpress/tags to determine which `wordpress:{wp_version}-php{php_version}-apache` image tags actually exist. Update the version matrix and `docker-compose.yml` to only include valid, buildable combinations.

## Details

### Problem

Not all PHP×WP combinations have official Docker images. For example:
- `wordpress:6.1-php8.5-apache` does NOT exist (PHP 8.5 is newer than WP 6.1's support window)
- `wordpress:7.0-php8.1-apache` may not exist if WP 7.0 dropped PHP 8.1 support

Building with a non-existent tag causes a Docker build failure.

### Approach

1. **Scrape / check Docker Hub** for all available `wordpress:*-apache` tags
2. **Build a compatibility map** in `scripts/config.sh` that defines which PHP versions are valid for each WP version
3. **Update `generate-compose.sh`** to skip invalid combinations
4. **Regenerate** `docker-compose.yml` and `db/init.sql` with only valid combos

### Possible Implementation

Add to `scripts/config.sh`:

```bash
# Valid PHP versions per WP version (based on Docker Hub availability)
declare -A VALID_PHP
VALID_PHP[6.1]="8.1 8.2"
VALID_PHP[6.2]="8.1 8.2"
VALID_PHP[6.3]="8.1 8.2"
VALID_PHP[6.4]="8.1 8.2 8.3"
VALID_PHP[6.5]="8.1 8.2 8.3"
VALID_PHP[6.6]="8.1 8.2 8.3"
VALID_PHP[6.7]="8.1 8.2 8.3 8.4"
VALID_PHP[6.8]="8.1 8.2 8.3 8.4"
VALID_PHP[6.9]="8.2 8.3 8.4"
VALID_PHP[7.0]="8.2 8.3 8.4 8.5"
```

Update `generate-compose.sh` to only generate services where the PHP version is in the valid list.

### Acceptance Criteria

- [ ] Compatibility map is based on actual Docker Hub tag availability
- [ ] `generate-compose.sh` only generates services for valid combos
- [ ] `docker compose build` succeeds for all generated services
- [ ] Invalid combos are clearly documented or commented out
