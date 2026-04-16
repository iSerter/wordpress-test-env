# Overview

A map of what this project is, how the moving parts fit together, and which
doc to read for each piece.

## What it is, in one sentence

A Docker-based test harness that runs **every supported PHP × WordPress
combination side-by-side** with WooCommerce + sample data pre-seeded, so a
plugin developer can verify compatibility across the whole matrix in one
command instead of manually booting environments.

## Core concept

```
┌─────────────┐  ┌─────────────┐       ┌─────────────┐
│  wp-81-61   │  │  wp-83-68   │  ...  │  wp-85-70   │   ← one container
│ PHP8.1+WP6.1│  │ PHP8.3+WP6.8│       │ PHP8.5+WP7.0│      per combo,
│  port 8161  │  │  port 8368  │       │  port 8570  │      self-named
└──────┬──────┘  └──────┬──────┘       └──────┬──────┘
       └────────────────┼─────────────────────┘
                        │
                 ┌──────┴──────┐
                 │  MariaDB    │   ← single shared DB,
                 │ 33 schemas  │      one schema per combo
                 └─────────────┘
```

**One container per PHP × WP combination.** Each gets its own port
(`{php_major}{php_minor}{wp_major}{wp_minor}` — e.g. `8368` for PHP 8.3 +
WP 6.8), its own named Docker volume for `wp-content/`, and its own
database schema (`wp_83_68`). A single shared MariaDB serves all of them.

**Ports encode versions.** You never have to look up "which port is PHP 8.3
+ WP 6.8" — it's `8368`, always. The scheme is self-documenting and stays
stable across regenerations.

**Volumes persist across restarts.** Stopping a container keeps its
`wp-content/` and its database rows. `reset.sh` is the only operation that
destroys data, and it asks for confirmation.

## Layered architecture

The repo is stacked in roughly five layers, each optional to the one below:

```
┌────────────────────────────────────────────────────────────────┐
│  5. Playwright fixture      →  E2E tests in consumer projects  │
│  4. GitHub Action           →  CI matrix with one YAML block   │
│  3. npm wrapper + template  →  Invoke from any plugin repo     │
│  2. Bash scripts + config   →  CLI surface (init, start, …)    │
│  1. Dockerfile + compose    →  The containers themselves       │
└────────────────────────────────────────────────────────────────┘
```

You can use any layer without the ones above it:

- **Layer 1 alone** — `docker compose up -d` and talk to WP containers by
  port, ignoring the bash tooling entirely.
- **Layer 2 alone** — the classic `git clone && ./scripts/init.sh` flow;
  no Node, no npm, no CI.
- **Layer 3** adds `npx @iserter/wp-test-env init 8.3 6.8` from your
  plugin's repo, plus the GitHub "Use this template" path.
- **Layer 4** adds one-step CI via `uses: iserter/wp-test-env@v1`.
- **Layer 5** adds a typed Playwright fixture for writing your own E2E tests.

Each layer is documented on its own page — see [Where to go next](#where-to-go-next) below.

## Key design decisions

### Backward-compatible by default

Every opt-in feature is gated on an env var or config value that defaults
to the pre-0.2.0 behavior. The
`tests/generate-compose.test.sh` golden-file test enforces this: with
`PLUGIN_PATHS` unset and no `wp-test-env.yml`, the generated
`docker-compose.yml` is byte-identical to the baseline captured in
`tests/fixtures/docker-compose.golden.yml`.

### Auto-generated compose

`docker-compose.yml` is never edited by hand — it's emitted by
`scripts/generate-compose.sh` from the matrix in `scripts/config.sh`. To
add or remove versions, edit `PHP_VERSIONS` / `WP_VERSIONS` and regenerate.

### Opt-in extension points

Rather than expose a plugin system, the repo offers a few simple extension
points:

| Extension | Use for |
|---|---|
| `PLUGIN_PATHS` env var | Bind-mount plugin directories into every container |
| `hooks/post-init.sh` | Custom logic at the end of `init.sh` |
| `wp-test-env.yml` | Commit a project-level config (matrix, plugins, seeding, hooks) |
| `SEED_WOOCOMMERCE=false` | Skip WC install for non-WC plugins |

### Precedence (when settings could come from multiple places)

1. **CLI arguments** — `./scripts/init.sh 8.3 6.8` always wins
2. **Environment variables** — `.env` or shell exports
3. **`wp-test-env.yml`** — committed project config
4. **Built-in defaults**

Rationale: project-level settings should be committed for reproducibility,
but individual contributors must be able to override them ad-hoc without
editing tracked files.

## Repo layout

```
scripts/            # Bash CLI — init.sh, start.sh, wp.sh, …
scripts/lib/        # Internal helpers (load-config.sh)
hooks/              # User-supplied lifecycle scripts (post-init.sh, …)
tests/              # Playwright specs + golden-file test for compose
tests/fixtures/     # Test-internal baselines (docker-compose.golden.yml)
playwright/         # Exported Playwright fixture (library source — published
                    # as @iserter/wp-test-env/playwright, compiled to dist/)
bin/                # Node shim used when installed via npm
examples/           # User-facing examples:
                    #   wp-test-env.yml       annotated config reference
                    #   example-plugin/       minimal bind-mount demo
                    #   example-plugin-with-tests/   consumed by the GH Action
                    #                                integration test
                    #   fixture-consumer/     consumer of the Playwright fixture
docs/dev-guide/     # This folder — deep dives on each feature
action.yml          # GitHub composite Action definition
Dockerfile          # Custom WP image layer (WP-CLI, cron, php.ini tweaks)
docker-compose.yml  # AUTO-GENERATED — do not edit
db/init.sql         # AUTO-GENERATED — creates one schema per valid combo
```

## Where to go next

- **Starting from zero:** [quickstart.md](quickstart.md)
- **Day-to-day scripts:** [helper-scripts.md](helper-scripts.md)
- **Live plugin dev:** [bind-mount.md](bind-mount.md)
- **Project config:** [config-file.md](config-file.md)
- **Custom init logic:** [hooks.md](hooks.md)
- **CI via GitHub Action:** [ci.md](ci.md)
- **Playwright in your plugin:** [playwright-fixture.md](playwright-fixture.md)
- **Built-in E2E suite:** [e2e-tests.md](e2e-tests.md)
