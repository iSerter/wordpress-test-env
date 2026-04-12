# WordPress Multi-Version Test Environment

Docker-based setup for testing WordPress plugins across **multiple PHP and WordPress versions** side-by-side. Each combination runs in its own container, sharing a single MariaDB database.

- **PHP versions**: 8.1, 8.2, 8.3, 8.4, 8.5
- **WP versions**: 6.1–6.9, 7.0 (beta)
- **33 valid combinations** (based on available Docker Hub images), each with WooCommerce + dummy data

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2+
- ~3–5 GB RAM for Docker (if running all 33 instances)
- Ports in the 8161–8570 range

## Quick Start

```bash
git clone <repo-url> && cd wordpress-test-env
cp .env.example .env

# Setup a single instance (fast)
./scripts/init.sh 8.1 6.9

# Or setup everything (33 instances — takes a while)
./scripts/init.sh
```

## Port Scheme

Ports follow the pattern `{php_major}{php_minor}{wp_major}{wp_minor}`:

```
PHP 8.1 + WP 6.1 → http://localhost:8161
PHP 8.3 + WP 6.8 → http://localhost:8368
PHP 8.5 + WP 7.0 → http://localhost:8570
```

### Full Port Table

Only valid combinations (based on Docker Hub image availability) are shown:

| WP ↓ \ PHP → | 8.1   | 8.2   | 8.3   | 8.4   | 8.5   |
|---------------|-------|-------|-------|-------|-------|
| 6.1           | 8161  | 8261  | –     | –     | –     |
| 6.2           | 8162  | 8262  | –     | –     | –     |
| 6.3           | 8163  | 8263  | –     | –     | –     |
| 6.4           | 8164  | 8264  | 8364  | –     | –     |
| 6.5           | 8165  | 8265  | 8365  | –     | –     |
| 6.6           | 8166  | 8266  | 8366  | –     | –     |
| 6.7           | 8167  | 8267  | 8367  | 8467  | –     |
| 6.8           | 8168  | 8268  | 8368  | 8468  | 8568  |
| 6.9           | 8169  | 8269  | 8369  | 8469  | 8569  |
| 7.0 (beta)    | –     | 8270  | 8370  | 8470  | 8570  |

## Default Credentials

| Role     | Username | Password   |
|----------|----------|------------|
| WP Admin | `admin`  | `admin`    |
| Customer | `john`   | `password` |

Admin dashboard: `http://localhost:{port}/wp-admin`

## Scripts

All scripts accept `[php_version wp_version]` to target a single instance, or no args for all.

| Script | Description |
|--------|-------------|
| `scripts/init.sh` | Full setup (build + configure + seed) |
| `scripts/start.sh` | Start instance(s) + shared DB |
| `scripts/stop.sh` | Stop instance(s), keeps data |
| `scripts/reset.sh` | Destroy container + volume (with confirmation) |
| `scripts/status.sh` | Show running instances |
| `scripts/setup-wordpress.sh` | Run WordPress core install |
| `scripts/install-woocommerce.sh` | Install and activate WooCommerce |
| `scripts/seed-data.sh` | Seed products, orders, customers, coupons |
| `scripts/generate-compose.sh` | Regenerate docker-compose.yml from version matrix |

Examples:
```bash
./scripts/start.sh 8.3 6.8     # start one instance
./scripts/stop.sh 8.3 6.8      # stop it
./scripts/reset.sh 8.3 6.8     # wipe and reset it
./scripts/init.sh 8.4 7.0      # full setup for PHP 8.4 + WP 7.0
```

## What's Pre-Installed

- **WordPress** with permalinks, debug mode, auto-updates disabled
- **WooCommerce** with USD/US store, Cash on Delivery enabled
- **Sample products** from WooCommerce sample data
- **5 test customers** with billing addresses
- **10 orders** in various statuses
- **3 coupons**: `SAVE10` (10% off), `FLAT5` ($5 off), `FREESHIP`

## Suggested Testing Strategy

For most plugin testing, focus on **boundary versions** — the lowest and highest supported. If a plugin works on the extremes, it will almost certainly work on versions in between, since deprecations and breaking changes happen at major boundaries.

**Recommended initial set** (6 instances):

```bash
./scripts/init.sh 8.1 6.1    # oldest PHP + oldest WP
./scripts/init.sh 8.1 6.9    # oldest PHP + newest stable WP
./scripts/init.sh 8.5 6.9    # newest PHP + newest stable WP
./scripts/init.sh 8.2 7.0    # WP 7.0 beta — major version boundary
./scripts/init.sh 8.5 7.0    # WP 7.0 beta + newest PHP
./scripts/init.sh 8.3 6.5    # mid-range sanity check
```

Expand to middle versions only if you suspect a version-specific issue.

## Architecture

```
┌─────────────┐  ┌─────────────┐       ┌─────────────┐
│  wp-81-61   │  │  wp-83-68   │  ...  │  wp-85-70   │
│ PHP8.1+WP6.1│  │ PHP8.3+WP6.8│       │ PHP8.5+WP7.0│
│  port 8161  │  │  port 8368  │       │  port 8570  │
└──────┬──────┘  └──────┬──────┘       └──────┬──────┘
       │                │                     │
       └────────────────┼─────────────────────┘
                        │
                 ┌──────┴──────┐
                 │     db      │
                 │ MariaDB 10.11│
                 │ 50 databases │
                 └─────────────┘
```

- Custom `Dockerfile` extends official `wordpress:{version}-php{version}-apache` images with WP-CLI
- Single shared MariaDB with one database per instance (`wp_81_61`, `wp_83_68`, etc.)
- Named Docker volumes persist data across restarts
- `docker-compose.yml` is auto-generated — edit versions in `scripts/config.sh` then run `scripts/generate-compose.sh`

## Changing the Version Matrix

1. Edit `PHP_VERSIONS` and/or `WP_VERSIONS` in `scripts/config.sh`
2. Run `./scripts/generate-compose.sh` to regenerate `docker-compose.yml` and `db/init.sql`
3. Run `./scripts/init.sh` to set up new instances

## Troubleshooting

**Docker image not found**: Not all PHP×WP combinations have official Docker images. For example, `wordpress:6.1-php8.5-apache` may not exist. Remove that combo from `config.sh` and regenerate.

**Port conflict**: If a port is in use, check which service occupies it and either stop that service or adjust the version matrix.

**Out of memory**: You don't need to run all 50 instances simultaneously. Start only what you need: `./scripts/start.sh 8.3 6.8`

**Slow first build**: First run builds Docker images and downloads MariaDB. Subsequent starts are fast.

**WooCommerce compatibility**: Older WP versions use pinned WooCommerce versions. See `scripts/install-woocommerce.sh` for the version map.

**DB init not running**: The `db/init.sql` only runs on first MariaDB startup. If you added new versions after the DB was created, either `./scripts/reset.sh` the whole stack or manually create the new database.
