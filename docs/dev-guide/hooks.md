# Lifecycle Hooks

`hooks/` is a lightweight extension point for running custom logic at
predictable moments during the test-env lifecycle. It exists so you can
tailor the environment to your plugin without forking the repo.

## Why hooks instead of editing `scripts/init.sh`?

- **Upgrade-safe** — `scripts/` is part of this repo's published surface;
  if you edit it you'll hit merge conflicts on every upgrade. Hooks live
  alongside your own code (or under `hooks/` in your checkout, which isn't
  overwritten by `git pull`).
- **Composable** — a hook is just a script. It can call any of the existing
  helpers (`install-plugin.sh`, `wp.sh`, etc.) without reimplementing them.
- **Opt-in** — missing hook file = no-op, zero cognitive overhead for users
  who don't need them.

## Supported hooks

### `hooks/post-init.sh`

Runs at the end of `scripts/init.sh`, after WordPress (and optionally
WooCommerce + sample data) are fully provisioned.

**Arguments:**
- `$1` — PHP version filter (e.g. `8.3`), or empty when init targeted all instances
- `$2` — WP version filter (e.g. `6.8`), or empty when init targeted all instances

**Typical uses:** installing additional plugins/themes, importing fixtures,
creating test users, tuning wp_options, running `wp rewrite flush`, etc.

### Overriding the path

Set `POST_INIT_HOOK=/path/to/script.sh` in `.env` or via `wp-test-env.yml`
to run a hook from outside `hooks/`. Useful when the test env is installed
via npm and your hook lives in your plugin repo.

## Example recipes

### Install developer plugins on every instance

```bash
#!/usr/bin/env bash
# hooks/post-init.sh
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$PROJECT_DIR/scripts/install-plugin.sh" query-monitor "${1:-}" "${2:-}"
"$PROJECT_DIR/scripts/install-plugin.sh" debug-bar "${1:-}" "${2:-}"
```

### Import a curated DB snapshot

```bash
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$PROJECT_DIR/scripts/import-db.sh" "${1:-}" "${2:-}" < fixtures/seed.sql
```

### Configure a plugin's options at boot

```bash
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$PROJECT_DIR/scripts/wp.sh" "${1:-}" "${2:-}" option update my_plugin_api_key "test-xyz"
```
