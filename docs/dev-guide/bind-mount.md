# Live Plugin Development via Bind-Mounts

Point the test environment at your plugin's working tree so edits reflect
instantly in every WP container — no zip rebuild, no `install-plugin.sh`
reinstall, no container restart.

## Quick start

1. Add your plugin path(s) to `.env`:

   ```bash
   # One plugin, repo-relative path
   PLUGIN_PATHS=./my-plugin

   # Multiple plugins, mix of relative + absolute
   PLUGIN_PATHS=./my-plugin,/Users/me/another-plugin
   ```

2. Regenerate `docker-compose.yml` so the mounts take effect:

   ```bash
   ./scripts/generate-compose.sh
   ```

3. Start (or restart) the instances you want to test on:

   ```bash
   ./scripts/init.sh 8.3 6.8
   ```

4. Activate the mounted plugin(s) across running instances:

   ```bash
   ./scripts/activate-mounted-plugins.sh
   ```

Edits to any file under a mounted path are visible in every WP container
immediately — just reload the browser.

## How it works

Each entry in `PLUGIN_PATHS` is resolved to an absolute path and mounted
into every `wp-*` service at:

```
/var/www/html/wp-content/plugins/<basename>
```

The basename (last path segment) becomes the plugin slug inside WordPress,
which is what `wp plugin activate <slug>` expects.

## Path resolution rules

- **Absolute paths** (`/Users/me/plugin`) are used as-is.
- **Relative paths** (`./plugin`, `../shared-lib`) are resolved against the
  `wp-test-env` repo root, not your current working directory.
- A non-existent path or a file (not a directory) fails fast with a clear
  error before any containers are touched.

## Commands

| Command | Purpose |
|---|---|
| `./scripts/activate-mounted-plugins.sh` | Activate all `PLUGIN_PATHS` entries on every running instance |
| `./scripts/activate-mounted-plugins.sh 8.3 6.8` | ...on a single instance |
| `./scripts/deactivate-mounted-plugins.sh` | Symmetric counterpart |

## Backward compatibility

When `PLUGIN_PATHS` is unset or empty, the generated `docker-compose.yml`
is byte-identical to pre-`v0.2.0` output. A CI job
(`.github/workflows/ci.yml`) enforces this via a golden-file test.

## Troubleshooting

**Plugin doesn't appear in wp-admin after setting PLUGIN_PATHS.**
Run `./scripts/generate-compose.sh` to rewrite `docker-compose.yml`, then
restart the affected containers: `./scripts/stop.sh 8.3 6.8 && ./scripts/start.sh 8.3 6.8`.

**Permission errors on file writes from inside the container.**
Bind-mounted directories inherit the host uid/gid. On Linux, ensure your
user owns the plugin directory. On macOS, Docker Desktop handles the
translation automatically.

**Edits not reflecting live.**
WordPress caches opcodes; if OPcache is enabled in your PHP config, edits
to `.php` files may need an opcache flush:
`./scripts/wp.sh 8.3 6.8 eval 'opcache_reset();'`
The default images ship with a low `opcache.revalidate_freq` so this is
rarely needed.
