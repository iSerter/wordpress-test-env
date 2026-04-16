# WordPress Multi-Version Test Environment

Docker-based setup for testing WordPress plugins across **multiple PHP and WordPress versions** side-by-side. Each combination runs in its own container, sharing a single MariaDB database.

- **PHP versions**: 8.1, 8.2, 8.3, 8.4, 8.5
- **WP versions**: 6.1–6.9, 7.0 (beta)
- **33 valid combinations** (based on available Docker Hub images), each with WooCommerce + dummy data

> **Already using [`@wordpress/env`](https://www.npmjs.com/package/@wordpress/env)?**
> Keep it for single-version local dev. Reach for this repo when you need
> to verify your plugin across the **full PHP × WP matrix** before a
> release, or when you want **WooCommerce + sample data pre-seeded** and a
> first-party **GitHub Action** for CI.

## Install

Pick whichever fits your workflow:

**npm / npx (recommended for plugin projects):**

```bash
# Run ad-hoc from your plugin directory — auto-mounts the current dir
npx @iserter/wp-test-env init 8.3 6.8

# Or add as a dev dependency
npm i -D @iserter/wp-test-env
npx wp-test-env init 8.3 6.8
```

**GitHub template repo:** Click **Use this template** on the repo page to
scaffold a copy with a starter `wp-test-env.yml.example` already pre-wired
for a `./plugin/` mount target — you just drop your plugin source in.
See [.github/TEMPLATE.md](.github/TEMPLATE.md).

**Clone directly (classic workflow):**

```bash
git clone https://github.com/iSerter/wordpress-test-env.git
cd wordpress-test-env
cp .env.example .env
./scripts/init.sh 8.1 6.9
```

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

## Project-level config (`wp-test-env.yml`)

Commit a `wp-test-env.yml` at the repo root to declare plugin paths, matrix
subset, seeding, and hooks once — then every script just Does The Right Thing:

```yaml
plugins: [ . ]
matrix:
  - { php: "8.3", wp: "6.8" }
seed:
  woocommerce: false
```

See [docs/dev-guide/config-file.md](docs/dev-guide/config-file.md) and
[`wp-test-env.schema.json`](wp-test-env.schema.json) for the full spec.
Requires [`yq`](https://github.com/mikefarah/yq) — only when a config file
exists. Precedence: CLI args > env vars > yml > defaults.

## Skipping WooCommerce (for non-WC plugins)

Set `SEED_WOOCOMMERCE=false` in `.env` to skip WooCommerce install and sample
data seeding — init becomes noticeably faster and produces a plain WordPress
environment. Default is `true` so existing setups are unchanged.

If `hooks/post-init.sh` exists, `init.sh` runs it at the end with
`$1=<php>` and `$2=<wp>` as args. See
[docs/dev-guide/hooks.md](docs/dev-guide/hooks.md).

## Live Plugin Development

To develop against the test env with live-reload (no zip rebuild), bind-mount
your plugin directory via `PLUGIN_PATHS` in `.env`:

```bash
# .env
PLUGIN_PATHS=./my-plugin,/Users/me/another-plugin
```

Then regenerate the compose file and (re)start an instance:

```bash
./scripts/generate-compose.sh
./scripts/init.sh 8.3 6.8
./scripts/activate-mounted-plugins.sh 8.3 6.8
```

Edits to files under `./my-plugin/` are reflected in every running container
instantly. See [docs/dev-guide/bind-mount.md](docs/dev-guide/bind-mount.md) for
full docs. Leaving `PLUGIN_PATHS` empty preserves the pre-`v0.2.0` behavior
exactly.

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
                 │ 33 databases │
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

**Out of memory**: You don't need to run all 33 instances simultaneously. Start only what you need: `./scripts/start.sh 8.3 6.8`

**Slow first build**: First run builds Docker images and downloads MariaDB. Subsequent starts are fast.

**WooCommerce compatibility**: Older WP versions use pinned WooCommerce versions. See `scripts/install-woocommerce.sh` for the version map.

**DB init not running**: The `db/init.sql` only runs on first MariaDB startup. If you added new versions after the DB was created, either `./scripts/reset.sh` the whole stack or manually create the new database.

## Helper Scripts

Additional utility scripts for day-to-day testing workflows. See [docs/dev-guide/helper-scripts.md](docs/dev-guide/helper-scripts.md) for full documentation.

| Script | Description |
|--------|-------------|
| `scripts/wp.sh` | Run WP-CLI commands: `./scripts/wp.sh 8.3 6.8 plugin list` |
| `scripts/logs.sh` | View container logs: `./scripts/logs.sh 8.3 6.8 --follow` |
| `scripts/open.sh` | Open instance in browser: `./scripts/open.sh 8.3 6.8` |
| `scripts/health-check.sh` | HTTP health check (CI-friendly): `./scripts/health-check.sh` |
| `scripts/install-plugin.sh` | Install plugin from slug or zip: `./scripts/install-plugin.sh query-monitor` |
| `scripts/export-db.sh` | Export database snapshot: `./scripts/export-db.sh 8.3 6.8` |
| `scripts/import-db.sh` | Import database snapshot: `./scripts/import-db.sh 8.3 6.8` |

## Use in GitHub Actions

This repo is also a reusable Action. Drop this into your plugin's workflow:

```yaml
- uses: actions/checkout@v4
- uses: iserter/wp-test-env@v1
  with:
    php: "8.3"
    wp: "6.8"
    plugin: .
    run: ./vendor/bin/phpunit
```

See [docs/dev-guide/ci.md](docs/dev-guide/ci.md) for matrix examples, all
inputs, and performance tips.

## E2E Browser Tests

Playwright-based tests that verify WordPress + WooCommerce across all running instances. See [docs/dev-guide/e2e-tests.md](docs/dev-guide/e2e-tests.md) for full documentation.

```bash
# Quick start (handles npm install + browser setup automatically)
./scripts/test.sh

# Test a single instance
./scripts/test.sh 8.3 6.8

# Smoke tests only
./scripts/test.sh --smoke

# Use Playwright directly
npm install && npx playwright install chromium
npx playwright test --project="php8.3-wp6.8"
```

Tests cover: admin login, dashboard health, REST API, WooCommerce storefront, cart, checkout, and order verification. Instances are discovered automatically from running Docker containers.
