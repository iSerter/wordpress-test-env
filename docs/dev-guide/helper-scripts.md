# Helper Scripts

Utility scripts for day-to-day WordPress testing workflows. All scripts live in `scripts/` and follow the same conventions as the core setup scripts.

## Conventions

- Source `config.sh` for shared functions, colors, and version matrix
- Accept optional `[php_version wp_version]` filter arguments
- Include `--help` output
- Use color-coded logging (`log_info`, `log_success`, `log_warn`, `log_error`)

## Scripts

### `scripts/wp.sh` — Run WP-CLI commands

Pass-through to WP-CLI inside a container. Requires both PHP and WP version args, followed by the WP-CLI command.

```bash
# List installed plugins
./scripts/wp.sh 8.3 6.8 plugin list

# Get a WordPress option
./scripts/wp.sh 8.3 6.8 option get siteurl

# Run a database query
./scripts/wp.sh 8.3 6.8 db query "SELECT count(*) FROM wp_posts"

# Export a specific table
./scripts/wp.sh 8.3 6.8 db export --tables=wp_options -
```

### `scripts/logs.sh` — View container logs

Tail or stream Docker container logs.

```bash
# Last 100 lines from all instances
./scripts/logs.sh

# Last 100 lines from one instance
./scripts/logs.sh 8.3 6.8

# Stream live logs
./scripts/logs.sh 8.3 6.8 --follow

# Last 50 lines
./scripts/logs.sh --tail 50
```

### `scripts/open.sh` — Open in browser

Open an instance in the default browser. Opens `wp-admin` by default.

```bash
# Open WP admin
./scripts/open.sh 8.3 6.8

# Open the frontend
./scripts/open.sh 8.3 6.8 --front
```

Uses `open` on macOS and `xdg-open` on Linux.

### `scripts/health-check.sh` — HTTP health check

Verify that instances are responding. Checks the homepage and REST API for each running instance. Exits non-zero if any check fails — suitable for CI.

```bash
# Check all running instances
./scripts/health-check.sh

# Check one instance
./scripts/health-check.sh 8.3 6.8
```

Output:
```
[INFO] Running health checks...

  wp-83-68      PHP 8.3   WP 6.8   home=200  api=200  PASS
  wp-84-70      PHP 8.4   WP 7.0   home=200  api=200  PASS

[ OK ] All 2 instance(s) healthy.
```

### `scripts/install-plugin.sh` — Install a plugin

Install a WordPress plugin from a wordpress.org slug or a local zip file.

```bash
# Install by slug on all running instances
./scripts/install-plugin.sh query-monitor

# Install by slug on one instance
./scripts/install-plugin.sh query-monitor 8.3 6.8

# Install from a zip file on all instances
./scripts/install-plugin.sh ./my-plugin.zip

# Install from a zip on one instance
./scripts/install-plugin.sh ./my-plugin.zip 8.3 6.8
```

Plugins are installed and activated. Use `--force` semantics — reinstalls if already present.

### `scripts/export-db.sh` — Export database snapshot

Export an instance's database to `snapshots/`.

```bash
./scripts/export-db.sh 8.3 6.8
# → snapshots/wp_83_68.sql
```

### `scripts/import-db.sh` — Import database snapshot

Restore a database from a SQL file. Prompts for confirmation before overwriting.

```bash
# Import the default snapshot
./scripts/import-db.sh 8.3 6.8

# Import a specific file
./scripts/import-db.sh 8.3 6.8 snapshots/wp_83_68.sql
```

## Typical Workflows

### Quick plugin test cycle

```bash
./scripts/start.sh 8.3 6.8
./scripts/export-db.sh 8.3 6.8        # save clean state
./scripts/install-plugin.sh ./my-plugin.zip 8.3 6.8
./scripts/open.sh 8.3 6.8
# ... test in browser ...
./scripts/import-db.sh 8.3 6.8        # restore clean state
```

### Check all instances are healthy after start

```bash
./scripts/start.sh
./scripts/health-check.sh
```

### Debug a specific instance

```bash
./scripts/logs.sh 8.3 6.8 --follow
./scripts/wp.sh 8.3 6.8 option get siteurl
./scripts/wp.sh 8.3 6.8 plugin list
```
