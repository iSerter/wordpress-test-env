# `wp-test-env.yml` — Project-level config

Declare your plugin's test-env expectations in a committed YAML file
instead of remembering CLI args and `.env` incantations.

## Quick start

Drop a `wp-test-env.yml` at the repo root:

```yaml
plugins: [ . ]
matrix:
  - { php: "8.3", wp: "6.8" }
seed:
  woocommerce: false
```

Then run any script as usual. `./scripts/init.sh` (no args) now boots only
the declared combo, with your plugin bind-mounted and WooCommerce skipped.

Prefer a hidden file? `.wp-test-env.yml` works too and takes the same shape.

## Schema

Full schema: [`wp-test-env.schema.json`](../../wp-test-env.schema.json).

Most editors (VS Code + YAML extension, JetBrains) validate YAML against a
schema when the first line points at it:

```yaml
# yaml-language-server: $schema=./wp-test-env.schema.json
```

### Fields

| Field | Type | Effect |
|---|---|---|
| `plugins` | `string[]` | Paths bind-mounted into every WP container at `wp-content/plugins/<basename>`. Absolute or relative to repo root. Populates `PLUGIN_PATHS`. |
| `matrix` | `{ php, wp }[]` | Restricts every iteration (init, start, stop, tests, compose generation) to the declared pairs. Combos outside this set are skipped as if they were invalid. |
| `seed.woocommerce` | `boolean` | When `false`, `init.sh` skips WC install + sample data. Populates `SEED_WOOCOMMERCE`. |
| `hooks.post-init` | `string` | Script run at the end of `init.sh` with `$1=<php>` `$2=<wp>`. Populates `POST_INIT_HOOK`. |

## Precedence

When a value could come from multiple sources, the resolution order is:

1. **CLI arguments** — e.g. `./scripts/init.sh 8.3 6.8` always wins
2. **Environment variables** — `.env` or shell exports
3. **`wp-test-env.yml`** — committed project config
4. **Built-in defaults** — e.g. `SEED_WOOCOMMERCE=true`

This order exists so that:
- A project can commit sane defaults without forcing contributors to edit YAML.
- A contributor can override any committed default from their shell or
  local `.env` without modifying tracked files.

Concrete example: if the yml says `seed.woocommerce: false` and a developer
runs `SEED_WOOCOMMERCE=true ./scripts/init.sh`, WooCommerce is installed.

## Requirements

`wp-test-env.yml` parsing requires [`yq`](https://github.com/mikefarah/yq).

- macOS: `brew install yq`
- Debian/Ubuntu: `apt install yq`
- Other: see the yq README

If `yq` is missing and a config file exists, scripts fail fast with an
install-instructions error. When there is no config file, `yq` is never
invoked and is not required.

## Reference example

See [`examples/wp-test-env.yml`](../../examples/wp-test-env.yml) for a
fully-annotated template you can copy.
