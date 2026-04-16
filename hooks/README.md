# Hooks

Optional scripts that run at well-defined points in the test-env lifecycle.
Every hook file is executed with `bash`; add a shebang if you prefer a
different interpreter.

Hooks are an **opt-in** extension mechanism. Nothing in this directory runs
unless you create the corresponding file.

## Available hooks

| File | When it runs | Args |
|---|---|---|
| `hooks/post-init.sh` | End of `scripts/init.sh`, after WP + (optional) WC install | `$1`=PHP version filter, `$2`=WP version filter (both empty when all instances were targeted) |

The path can be overridden with the `POST_INIT_HOOK` env var, which is useful
when driven from `wp-test-env.yml`.

## Example: install extra plugins across instances

```bash
#!/usr/bin/env bash
# hooks/post-init.sh
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

"$PROJECT_DIR/scripts/install-plugin.sh" query-monitor "${1:-}" "${2:-}"
"$PROJECT_DIR/scripts/install-plugin.sh" debug-bar "${1:-}" "${2:-}"
```

Make it executable (`chmod +x hooks/post-init.sh`) — `bash` will run it
regardless, but being consistent helps.
