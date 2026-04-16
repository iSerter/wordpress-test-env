# Task: Improve Developer Integration Experience

**Phase:** 2 — DX & Integration
**Status:** Planning
**Depends on:** Phase 1 complete (base multi-version setup + helper scripts + E2E tests)
**Supersedes:** `08-phase2-plugin-development-branch.md` (bind-mount becomes a first-class
feature on `main` instead of a separate `with-plugins` branch)

## Objective

Reduce the friction for a third-party WordPress plugin developer to use this repo as their
test environment. Today the repo assumes the developer clones it and works *inside* it; the
goal is to let them consume it *from* their own plugin project with minimal setup.

## Guiding Principles

### Backward compatibility

Every change below must preserve the existing workflow. A user who already cloned the repo
and runs `./scripts/init.sh` / `./scripts/start.sh` must see identical behavior after these
changes land. Specifically:

- No existing script name, argument order, or exit-code contract changes.
- No existing environment variable is renamed; new ones are additive and default to "off."
- `docker-compose.yml` layout (service names, ports, volumes, DB schema) is unchanged for
  users who do not opt into new features.
- All new features are opt-in via `.env` flags, new script flags, or separate entry points.

### Versioning

- **Cut `v0.1.0` first** from current `main` to immortalize the existing feature set as a
  tagged release. release-please is already configured (`.release-please-manifest.json` +
  `.github/workflows/release-please.yml`), so this is done by merging the release-please PR
  once there is conventional-commit history on `main`.
- Land the work below as `feat:` commits on `main`. release-please will propose `v0.2.0`
  (minor bump) because `bump-minor-pre-major: true` is set in `release-please-config.json`.
- Any change that *does* break backward compatibility must be deferred to `v1.0.0` and
  called out in the PR description + CHANGELOG.

---

## Part A — Bind-mount local plugins (highest leverage)

Let developers point the test env at their working tree so code changes are reflected
instantly in all containers, with no zip-rebuild / reinstall cycle.

### Configuration

Add a new `.env` variable (and document in `.env.example`):

```bash
# Comma-separated absolute or repo-relative paths. Each directory is mounted into
# /var/www/html/wp-content/plugins/<basename> on every WP service.
PLUGIN_PATHS=/Users/me/my-plugin,../shared-lib
```

When `PLUGIN_PATHS` is empty or unset, behavior is identical to today.

### Implementation

- Update `scripts/generate-compose.sh` to read `PLUGIN_PATHS` from `.env` and emit extra
  `volumes:` entries on each `wp-*` service.
- Resolve each path to an absolute path at generate time (so the generated compose file
  is portable-within-a-checkout).
- Add a `scripts/activate-mounted-plugins.sh` that runs `wp plugin activate` for each
  mounted plugin's directory name.
- Add `scripts/deactivate-mounted-plugins.sh` for symmetry.

### Acceptance criteria

- [ ] With `PLUGIN_PATHS` empty, `generate-compose.sh` produces byte-identical output to
      today (golden-file test in CI).
- [ ] With `PLUGIN_PATHS=./fixtures/example-plugin`, editing a file in
      `fixtures/example-plugin/` is reflected inside every running container without a
      rebuild or restart.
- [ ] `activate-mounted-plugins.sh` activates all mounted plugins across all running
      instances.

---

## Part B — Invoke from outside the repo

Today every script assumes `$PWD` is the repo root. Make it possible to drive the env
from the developer's own project.

### B1. npm package wrapper

- Publish the repo (or a thin wrapper around it) as `@iserter/wp-test-env` with a `bin`
  entry: `wp-test-env`.
- The `bin` locates the installed package's `scripts/` dir and forwards the subcommand:
  `wp-test-env init 8.3 6.8` → `scripts/init.sh 8.3 6.8`, but run against the *caller's*
  `$PWD` as the plugin source.
- When invoked this way, `PLUGIN_PATHS` defaults to `.` (caller's cwd) unless overridden.

### B2. GitHub template repository

- Flip the "Template repository" flag on the GitHub repo settings so developers can click
  "Use this template" and get their own fork pre-shaped with a `./plugin/` directory
  wired into `PLUGIN_PATHS`.
- Add `./plugin/.gitkeep` + a `TEMPLATE.md` explaining the template usage.

### Acceptance criteria

- [ ] `npx @iserter/wp-test-env init 8.3 6.8` run from an arbitrary directory spins up a
      WP instance with that directory mounted as a plugin.
- [ ] Template-repo checkout with a plugin dropped in `./plugin/` just works with
      `./scripts/init.sh`.

---

## Part C — Project-level config file

Let the developer declare intent in their own repo instead of remembering script args.

### Spec

A `wp-test-env.yml` (or `.wptestenv.yml`) at the caller's project root:

```yaml
plugins:
  - .
  - ../shared-lib
matrix:
  - { php: "8.1", wp: "6.9" }
  - { php: "8.5", wp: "7.0" }
pre-install:
  - query-monitor
seed:
  woocommerce: false   # skip WC install + sample data for non-WC plugins
hooks:
  post-init: ./scripts/my-setup.sh
```

### Implementation

- New `scripts/lib/load-config.sh` that parses the YAML (yq or a minimal awk parser) and
  exports env vars consumed by existing scripts.
- When the config file is absent, every script behaves exactly as today.
- `seed.woocommerce: false` short-circuits `install-woocommerce.sh` and `seed-data.sh`.

### Acceptance criteria

- [ ] `wp-test-env up` (or equivalent) with a config file boots only the declared matrix.
- [ ] Running without a config file is a no-op change from current behavior.

---

## Part D — Reusable GitHub Action

Package the most common CI use case as a single Action.

```yaml
- uses: iserter/wp-test-env@v1
  with:
    php: "8.3"
    wp: "6.8"
    plugin: .
    run: ./vendor/bin/phpunit
```

### Implementation

- New `action.yml` at repo root (composite action).
- Internally: checks out this repo into `$RUNNER_TEMP`, writes a `.env` with
  `PLUGIN_PATHS`, runs `scripts/init.sh $php $wp`, then executes the user's `run`
  command inside the WP container via `scripts/wp.sh` or a new `scripts/exec.sh`.
- Tag `v1` pointing at the first release that contains this file, following the GitHub
  Actions "major version tag" convention.

### Acceptance criteria

- [ ] A sample consumer workflow in `.github/workflows/integration-example.yml`
      demonstrates the action green-building against a fixture plugin.

---

## Part E — Playwright fixture export

Export the test infrastructure so consumers can write their own E2E tests on top.

- Publish a `@iserter/wp-test-env/playwright` subpath export with a `wpFixture` that
  returns a booted instance URL + pre-authenticated admin page.
- Consumer usage:
  ```ts
  import { test } from '@iserter/wp-test-env/playwright';
  test('my plugin admin page loads', async ({ wpAdminPage }) => {
    await wpAdminPage.goto('/wp-admin/admin.php?page=my-plugin');
  });
  ```

### Acceptance criteria

- [ ] A fixture consumer project (can live under `examples/`) passes its own Playwright
      suite using only the published fixture.

---

## Part F — Decouple opinionated seeding

WooCommerce + sample orders is valuable for WC-plugin developers, wasted time for
everyone else.

- Make `install-woocommerce.sh` and `seed-data.sh` opt-in via `.env`:
  ```bash
  SEED_WOOCOMMERCE=true   # current default; unchanged
  SEED_WOOCOMMERCE=false  # new: skip WC entirely
  ```
- Default stays `true` so existing users see no change.
- Add a `hooks/` convention: if `hooks/post-init.sh` exists in the caller's project, run
  it after WP install + (optional) WC seeding.

### Acceptance criteria

- [ ] `SEED_WOOCOMMERCE=false ./scripts/init.sh 8.3 6.8` yields a WP install with no
      WooCommerce, no sample data — and is measurably faster than the default.
- [ ] Default behavior is unchanged when the flag is unset.

---

## Release Plan

1. **Tag `v0.1.0`** from current `main` via release-please (merge the auto-opened release
   PR). This freezes the existing feature set.
2. Land Parts A–F as independent `feat:` commits / PRs. Each should stand alone so they
   can be cherry-picked or reverted individually.
3. Merge the release-please PR again once all parts land — release-please bumps to
   `v0.2.0` automatically.
4. Publish npm package `@iserter/wp-test-env@0.2.0` aligned with the git tag.
5. Tag `v1` (floating major tag) for the GitHub Action only after Part D ships.

## Suggested Implementation Order

Parts are independent, but A unlocks the most value and every other part assumes it
exists. Recommended order:

1. **Part A** — bind-mount. Delivers most of the value on its own.
2. **Part F** — decouple seeding. Small, high-impact, stands alone.
3. **Part C** — config file. Makes A+F ergonomic.
4. **Part B** — npm + template. Distribution.
5. **Part D** — GitHub Action. Depends on A.
6. **Part E** — Playwright fixture. Nice-to-have, can slip to `v0.3.0`.

---

## Comparison: How This Repo Differs From `@wordpress/env`

`@wordpress/env` (wp-env) is the official tool from the WordPress core team and is the
obvious incumbent a developer will reach for. We should not pretend it doesn't exist —
instead, be explicit about the cases where it is the right tool and the cases where
this repo wins.

### Positioning, in one sentence

> **wp-env** is a single-environment development sandbox.
> **This repo** is a multi-version *compatibility matrix* — designed to answer
> "does my plugin work across all supported PHP × WordPress combinations?" in one
> command, with realistic WooCommerce data pre-seeded.

They are complementary more than competing. A developer can keep using wp-env for
day-to-day local dev and reach for this repo when they need matrix coverage before a
release.

### Where this repo is structurally better

| Capability | `@wordpress/env` | This repo |
|---|---|---|
| **Parallel PHP versions** | One at a time (single `phpVersion` field per env) | Up to 5 simultaneously (8.1 → 8.5) |
| **Parallel WordPress versions** | Separate configs + manual port juggling | 10 versions simultaneously (6.1 → 7.0 beta) |
| **Full matrix in one command** | No — N configs, N invocations | Yes — `./scripts/init.sh` spins up all 33 valid combos |
| **WooCommerce pre-installed** | No — manual via `plugins` array | Yes — version-pinned per WP release |
| **Seeded e-commerce data** | No | Yes — products, customers, orders, coupons |
| **E2E test suite included** | No | Yes — Playwright, auto-discovers all running instances |
| **Port scheme encodes version** | No — sequential or manual | Yes — `8368` means PHP 8.3 + WP 6.8 (self-documenting) |
| **Shared DB across instances** | No — each env has its own MariaDB | Yes — one MariaDB, one database per combo |
| **Realistic cron** | WP-Cron (on page load) | System cron + WP-Cron + Action Scheduler every minute |
| **Ready-made GitHub Action** | No official action — users hand-roll `npx @wordpress/env start` in workflows; a few third-party community actions exist but none are endorsed | Planned in Part D — first-party composite action with matrix-aware inputs |

### Where `@wordpress/env` currently wins (and how we close the gap)

These are the things wp-env does well that we should match, tracked in the parts above:

| wp-env feature | Our gap today | Closed by |
|---|---|---|
| `npx @wordpress/env start` from any plugin dir | Must clone this repo and `cd` into it | **Part B** (npm wrapper) |
| `.wp-env.json` schema-validated config | Scripts take positional args only | **Part C** (`wp-test-env.yml`) |
| Bind-mount plugin source by default | Plugin installed from zip, no live edit | **Part A** (`PLUGIN_PATHS`) |
| Official WordPress core team backing | Solo-maintained | (accept — differentiate on matrix depth) |
| Broad docs + Stack Overflow presence | Minimal | (accept — follows from adoption) |

After Parts A+B+C ship in `v0.2.0`, the ergonomics gap closes and the structural
advantages (matrix, seeding, E2E) become net-wins with no ergonomic tax.

### What we explicitly do *not* try to do

To keep the scope honest:

- **Not a replacement for wp-env in single-version dev.** If a developer only needs one
  PHP + one WP version, wp-env is lighter. We don't try to beat it on that axis.
- **Not a Playground/WebAssembly runtime.** wp-env has a `--runtime=playground` mode for
  browser-based dev. We are Docker-only by design (matrix testing needs real PHP).
- **Not a multisite-first tool.** wp-env has first-class multisite support; we can add
  it later if demand shows up, but it's not on the v0.2.0 path.

### Messaging for the README

Once v0.2.0 ships, the README should open with a short "When to use this vs wp-env" box
near the top, so a developer evaluating both doesn't have to reverse-engineer the
positioning. Draft:

> **Already using `@wordpress/env`?** Keep it for single-version local dev. Use this
> repo when you need to verify your plugin across the full PHP × WordPress matrix before
> a release, or when you want WooCommerce + sample data pre-seeded.
