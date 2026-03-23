# Task 01: Docker Compose & Dockerfile Setup

**Phase:** 1 - Core Infrastructure
**Status:** Pending
**Depends on:** None

## Objective

Create the `docker-compose.yml` and a custom `Dockerfile` that spins up 10 WordPress instances (6.1–6.9 and 7.0), each with its own MariaDB database.

## Details

### WordPress Versions & Port Mapping

| Version | Host Port | WP Container         | DB Container         |
|---------|-----------|----------------------|----------------------|
| 6.1     | 8061      | wp-6.1               | db-6.1               |
| 6.2     | 8062      | wp-6.2               | db-6.2               |
| 6.3     | 8063      | wp-6.3               | db-6.3               |
| 6.4     | 8064      | wp-6.4               | db-6.4               |
| 6.5     | 8065      | wp-6.5               | db-6.5               |
| 6.6     | 8066      | wp-6.6               | db-6.6               |
| 6.7     | 8067      | wp-6.7               | db-6.7               |
| 6.8     | 8068      | wp-6.8               | db-6.8               |
| 6.9     | 8069      | wp-6.9               | db-6.9               |
| 7.0     | 8070      | wp-7.0               | db-7.0               |

### Architecture Decisions

- **Custom Dockerfile**: Extend the official `wordpress:<version>-php8.x-apache` images to add WP-CLI. This avoids needing to install WP-CLI at runtime.
- **MariaDB**: Use `mariadb:10.11` (LTS) for all instances. One DB container per WP instance for isolation.
- **Volumes**: Named volumes for each DB (`db-data-6.1`, etc.) and each WP instance (`wp-data-6.1`, etc.) so data persists across restarts.
- **Network**: Single shared Docker network (`wp-test-net`).
- **Health checks**: DB containers should have health checks so WP containers wait for DB readiness.

### Files to Create

- `Dockerfile` — extends official WP image, installs WP-CLI
- `docker-compose.yml` — all 20 services (10 WP + 10 DB)
- `.env` — default environment variables (DB credentials, WP admin user/pass, etc.)
- `.env.example` — template for `.env`

### Acceptance Criteria

- [ ] `docker compose up -d` starts all 20 containers
- [ ] Each WordPress instance is accessible at its mapped port
- [ ] WP-CLI is available inside each WP container (`docker compose exec wp-6.1 wp --info`)
- [ ] DB containers have health checks and WP containers depend on them
