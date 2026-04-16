# Implementation Plan: Better Developer Experience

**Implements:** [`improve-developer-experience.md`](./improve-developer-experience.md)
**Status:** Planning
**Target release:** `v0.2.0`

This document turns the *what* described in `improve-developer-experience.md` into the
*how* — concrete PRs, file-level changes, commit messages, verification steps, and
rollback plans.

---

## PR 0 — Pre-flight: cut `v0.1.0` baseline

Before any new work lands, freeze the existing feature set as `v0.1.0` so everything
after is clearly "next version."

### Steps

1. Audit commit history on `main` — confirm `feat:` / `fix:` conventional-commit prefixes
   are in place since the manifest anchor (`0.1.0`). A quick `git log --oneline` check is
   enough; current commits (`4314da9`, `0d302d5`, `d932571` …) follow the convention.
2. Push a trivial `chore:` commit if needed to retrigger the release-please workflow.
3. Wait for the release-please PR to open, review its generated `CHANGELOG.md`, and merge.
4. Confirm: `git tag` lists `v0.1.0`, GitHub Releases shows the tag with changelog.

### Rollback

No rollback — tags are additive. If the changelog has errors, amend via a follow-up PR
to `CHANGELOG.md` and cut `v0.1.1` as a doc-only patch.

### Exit criteria

- [ ] `git describe --tags` on `main` returns `v0.1.0`
- [ ] `.release-please-manifest.json` updated to `"0.1.0"` (should already be)
- [ ] `CHANGELOG.md` exists at repo root

---

## PR 1 — Part A: Bind-mount local plugins

**Branch:** `feat/bind-mount-plugins`
**Depends on:** PR 0
**Estimated blast radius:** moderate — touches compose generation, the most load-bearing
piece of infrastructure.

### File-level changes

| Path | Action | Notes |
|---|---|---|
| `scripts/config.sh` | Edit | Add `parse_plugin_paths()` helper. Reads `PLUGIN_PATHS`, splits on comma, resolves each entry to absolute path. Exports `PLUGIN_MOUNTS` as bash array. |
| `scripts/generate-compose.sh` | Edit | Inside the per-service `cat >> "$COMPOSE" <<EOF` block, conditionally append one `- /abs/path:/var/www/html/wp-content/plugins/<basename>` line per `PLUGIN_MOUNTS` entry. |
| `.env.example` | Edit | Append documented `PLUGIN_PATHS=` line. |
| `scripts/activate-mounted-plugins.sh` | New | Iterates `PLUGIN_MOUNTS`, runs `wp_exec "$svc" plugin activate "$basename"` on each. Supports the same `[php wp]` filter args as peer scripts. |
| `scripts/deactivate-mounted-plugins.sh` | New | Symmetric counterpart. |
| `fixtures/example-plugin/example-plugin.php` | New | Minimal `<?php /* Plugin Name: Example */` stub used by integration tests. |
| `tests/generate-compose.test.sh` | New | Golden-file test: runs `generate-compose.sh` with `PLUGIN_PATHS=""` and diffs against `tests/fixtures/docker-compose.golden.yml`. |
| `tests/fixtures/docker-compose.golden.yml` | New | Captured current output (literally `cp docker-compose.yml tests/fixtures/docker-compose.golden.yml` once on a clean checkout). |
| `.github/workflows/ci.yml` | New/Edit | Run the golden-file test on every PR. |
| `docs/dev-guide/bind-mount.md` | New | How-to with screenshots/examples. |
| `README.md` | Edit | Add a brief "Live plugin development" subsection linking to the dev-guide page. |

### Path resolution — cross-platform detail

macOS `realpath` ships in coreutils only if installed via brew; the BSD version differs.
Use this portable shim inside `parse_plugin_paths()`:

```bash
_abspath() {
    # Prefer realpath (GNU), fall back to python, last-resort: cd+pwd
    if command -v realpath >/dev/null 2>&1; then
        realpath "$1"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
    else
        (cd "$(dirname "$1")" && printf '%s/%s\n' "$(pwd)" "$(basename "$1")")
    fi
}
```

### Commits (conventional)

1. `feat(scripts): support PLUGIN_PATHS for bind-mounted plugin development`
2. `test(ci): add golden-file test for generate-compose.sh`
3. `docs(dev-guide): document live plugin development workflow`

### Verification

```bash
# 1. No-op when unset — byte-identical compose output
PLUGIN_PATHS='' ./scripts/generate-compose.sh
diff docker-compose.yml tests/fixtures/docker-compose.golden.yml  # must be empty

# 2. Mounts appear when set
PLUGIN_PATHS=./fixtures/example-plugin ./scripts/generate-compose.sh
grep -c "wp-content/plugins/example-plugin" docker-compose.yml  # expect 33

# 3. Live-reload works end-to-end
PLUGIN_PATHS=$(pwd)/fixtures/example-plugin ./scripts/generate-compose.sh
./scripts/init.sh 8.3 6.8
./scripts/activate-mounted-plugins.sh 8.3 6.8
# Edit fixtures/example-plugin/example-plugin.php (change the Plugin Name)
# Refresh http://localhost:8368/wp-admin/plugins.php — new name appears without rebuild
```

### Rollback

`PLUGIN_PATHS` is purely additive. Unset the variable, rerun `generate-compose.sh`, and
output is byte-identical to pre-PR. No volume, no DB, no image changes.

---

## PR 2 — Part F: Decouple opinionated seeding

**Branch:** `feat/optional-woocommerce`
**Depends on:** PR 0 (independent of PR 1, but land after so the sequence of `feat:`
commits tells a coherent story in the changelog).
**Blast radius:** small — one flag check in one script.

### File-level changes

| Path | Action | Notes |
|---|---|---|
| `.env.example` | Edit | Add `SEED_WOOCOMMERCE=true` with comment. |
| `scripts/init.sh` | Edit | Gate the `install-woocommerce.sh` and `seed-data.sh` calls (lines 49–55) behind `[[ "${SEED_WOOCOMMERCE:-true}" == "true" ]]`. Add a `log_info "Skipping WooCommerce (SEED_WOOCOMMERCE=false)"` branch. |
| `scripts/init.sh` | Edit | After step 6, add: `if [[ -f "$PROJECT_DIR/hooks/post-init.sh" ]]; then bash "$PROJECT_DIR/hooks/post-init.sh" "$FILTER_PHP" "$FILTER_WP"; fi`. |
| `hooks/.gitkeep` | New | Ensures the directory exists. |
| `hooks/README.md` | New | Documents the convention and passes-through args. |
| `docs/dev-guide/hooks.md` | New | Example post-init.sh that installs a custom plugin. |
| `README.md` | Edit | Document `SEED_WOOCOMMERCE` in the env-vars section. |

### Commits

1. `feat(scripts): gate WooCommerce seeding behind SEED_WOOCOMMERCE flag`
2. `feat(scripts): run hooks/post-init.sh after init when present`
3. `docs: document seeding flag and hooks convention`

### Verification

```bash
# Default unchanged
./scripts/reset.sh 8.3 6.8 --yes
time ./scripts/init.sh 8.3 6.8  # note baseline time
./scripts/wp.sh 8.3 6.8 plugin is-active woocommerce  # exit 0

# Opt-out is faster and WC-free
./scripts/reset.sh 8.3 6.8 --yes
SEED_WOOCOMMERCE=false time ./scripts/init.sh 8.3 6.8  # should be ≥30s faster
./scripts/wp.sh 8.3 6.8 plugin is-active woocommerce  # exit 1

# Hook fires
printf '#!/usr/bin/env bash\necho "HOOK RAN for $1 $2"\n' > hooks/post-init.sh
chmod +x hooks/post-init.sh
./scripts/reset.sh 8.3 6.8 --yes
./scripts/init.sh 8.3 6.8 | grep "HOOK RAN for 8.3 6.8"
```

### Rollback

Pure opt-in. If the flag breaks something, users leave it unset and behavior is today's.

---

## PR 3 — Part C: Project-level config file (`wp-test-env.yml`)

**Branch:** `feat/config-file`
**Depends on:** PR 1, PR 2 (reads back the flags those introduce).
**Blast radius:** moderate — touches every top-level script.

### Design decision: YAML parser

Requires `yq` (Go-based, single binary, widely available). Rationale:

- Pure-bash YAML parsing is fragile. The failure modes are worse than "install yq."
- `yq` is already standard in WordPress CI pipelines.
- Python fallback adds complexity without solving the "bash purists" objection.

The loader issues a clear error if `yq` is missing:
```
[ ERR ] wp-test-env.yml found but `yq` is not installed.
        Install: brew install yq  |  apt install yq  |  see https://github.com/mikefarah/yq
```

### Precedence rules

1. Explicit CLI args (e.g. `./scripts/init.sh 8.3 6.8`) — highest
2. Environment variables (from `.env` or the user's shell)
3. `wp-test-env.yml` values
4. Built-in defaults — lowest

Rationale: CLI and env are ephemeral/developer-specific; the yml is project-committed.
A developer must be able to override committed config without editing the file.

### File-level changes

| Path | Action | Notes |
|---|---|---|
| `scripts/lib/load-config.sh` | New | Sourced by top-level scripts. Parses `wp-test-env.yml` via `yq`, exports `WPTE_PLUGINS`, `WPTE_MATRIX`, `WPTE_SEED_WOOCOMMERCE`, `WPTE_HOOKS_POST_INIT`. Missing file → silent no-op. |
| `scripts/config.sh` | Edit | Source `load-config.sh` after `.env` load. Apply precedence: existing env vars are not overwritten. |
| `wp-test-env.schema.json` | New | JSON Schema for editor validation, published alongside the repo. |
| `docs/dev-guide/config-file.md` | New | Full schema reference + examples. |
| `examples/wp-test-env.yml` | New | Annotated reference config. |
| `README.md` | Edit | Mention config-file path as an alternative to env vars. |

### Config schema (v1)

```yaml
# All fields optional. Missing file = zero behavioral change.
plugins:            # list of paths; each mounted at /var/www/html/wp-content/plugins/<basename>
  - .
  - ../shared-lib
matrix:             # subset of the full PHP×WP matrix to run
  - { php: "8.1", wp: "6.9" }
  - { php: "8.5", wp: "7.0" }
seed:
  woocommerce: false    # default: true
hooks:
  post-init: ./scripts/my-setup.sh
```

### Commits

1. `feat(scripts): add scripts/lib/load-config.sh wp-test-env.yml loader`
2. `feat(scripts): apply env-over-yml-over-defaults precedence`
3. `docs: add wp-test-env.yml reference and JSON schema`

### Verification

```bash
# No file = unchanged behavior
rm -f wp-test-env.yml
./scripts/init.sh --help  # baseline

# File with no overrides = unchanged behavior
printf "plugins: []\n" > wp-test-env.yml
./scripts/init.sh 8.3 6.8  # same as before

# Matrix subset respected
cat > wp-test-env.yml <<EOF
matrix:
  - { php: "8.3", wp: "6.8" }
EOF
./scripts/init.sh  # boots only 8.3+6.8, not all 33

# Env wins over yml
SEED_WOOCOMMERCE=true ./scripts/init.sh  # overrides yml's `woocommerce: false`
```

### Rollback

Delete `wp-test-env.yml` → behavior is today's. No lockfile, no persistent state.

---

## PR 4 — Part B: npm wrapper + template repo

**Branch:** `feat/npm-package`
**Depends on:** PR 1, PR 3 (the wrapper sets `PLUGIN_PATHS=$PWD` by default, which
requires Part A to have shipped).
**Blast radius:** moderate — ships the repo as a distributable package.

### File-level changes

| Path | Action | Notes |
|---|---|---|
| `package.json` | Edit | Flip `"private": false`; add `"name": "@iserter/wp-test-env"`, `"version": "0.2.0"`, `"bin": { "wp-test-env": "./bin/wp-test-env.js" }`, `"files": ["scripts/", "bin/", "hooks/", "Dockerfile", "docker-entrypoint-extra.sh", "apache2-custom-foreground", "php-uploads.ini", "wp-test-env.schema.json"]`. |
| `bin/wp-test-env.js` | New | Node shim: resolves the installed package root, cd's into it, exports `WPTE_CALLER_CWD=$PWD`, then `spawn("bash", ["scripts/${subcommand}.sh", ...args])`. Sets `PLUGIN_PATHS=$WPTE_CALLER_CWD` by default if not already set. |
| `bin/wp-test-env.js` | New | Also supports `--version`, `--help`, and a `init --self` flag that copies `.env.example`, `wp-test-env.yml.example` to caller's cwd. |
| `.github/workflows/npm-publish.yml` | New | On release tag, `npm publish --access public`. Uses `NPM_TOKEN` secret. |
| `plugin/.gitkeep` | New | Pre-shapes the template-repo's mount target. |
| `.wp-test-env.example.yml` | New | Example config pre-wired for `./plugin/`. |
| `.github/TEMPLATE.md` | New | Instructions shown to users who click "Use this template." |
| `README.md` | Edit | Add an "Install via npm" section near the top. |

### Manual GitHub settings (documented, not automated)

- Flip the "Template repository" checkbox in Settings → General.
- Add `NPM_TOKEN` repository secret (generate an automation token on npm scoped to
  `@iserter/*`).
- Verify the `@iserter` org exists on npm; create it if not.

### Commits

1. `feat(package): publish as @iserter/wp-test-env with npx entry`
2. `ci: auto-publish to npm on release tag`
3. `feat(template): pre-shape repo for "Use this template" flow`
4. `docs: document npm and template-repo install paths`

### Verification

```bash
# Local install smoke test
npm pack
mkdir /tmp/dummy-plugin && cd /tmp/dummy-plugin
npm init -y
npm i $OLDPWD/iserter-wp-test-env-0.2.0.tgz
npx wp-test-env init 8.3 6.8
# Confirm /tmp/dummy-plugin auto-mounted at /var/www/html/wp-content/plugins/dummy-plugin

# Template-repo flow (manual)
# 1. Click "Use this template" on GitHub → create new repo
# 2. Drop a plugin file into ./plugin/
# 3. Run ./scripts/init.sh 8.3 6.8
# 4. Confirm the plugin appears in wp-admin
```

### Rollback

Unpublish via `npm unpublish @iserter/wp-test-env@0.2.0` within 72 hours if needed.
After 72h, publish a `0.2.1` with a `deprecated` flag pointing at the fix. The git repo
itself is unaffected.

---

## PR 5 — Part D: Reusable GitHub Action

**Branch:** `feat/github-action`
**Depends on:** PR 1 (needs `PLUGIN_PATHS`).
**Blast radius:** small — new files only, no behavior change for existing users.

### File-level changes

| Path | Action | Notes |
|---|---|---|
| `action.yml` | New | Composite action at repo root (required location for `uses: org/repo@ref`). Inputs: `php`, `wp`, `plugin` (default `.`), `run`, `woocommerce` (default `true`). |
| `action.yml` | New | Steps: checkout this repo into `$RUNNER_TEMP/wp-test-env`; write `.env` with `PLUGIN_PATHS=${{ github.workspace }}/${{ inputs.plugin }}` + `SEED_WOOCOMMERCE=${{ inputs.woocommerce }}`; run `./scripts/init.sh ${{ inputs.php }} ${{ inputs.wp }}`; if `inputs.run` is set, `./scripts/wp.sh ${{ inputs.php }} ${{ inputs.wp }} eval-file` or shell into container and exec. |
| `.github/workflows/integration-example.yml` | New | Self-validation: uses `./` as the action against `fixtures/example-plugin`. PR-blocking. |
| `fixtures/example-plugin-with-tests/` | New | Minimal plugin + a `phpunit.xml` that the integration workflow runs. |
| `docs/dev-guide/ci.md` | New | Full workflow examples including matrix strategy. |
| `README.md` | Edit | Add "Use in GitHub Actions" section with the one-block example. |

### Matrix usage documented in README

```yaml
jobs:
  test:
    strategy:
      matrix:
        include:
          - { php: "8.1", wp: "6.9" }
          - { php: "8.5", wp: "7.0" }
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: iserter/wp-test-env@v1
        with:
          php: ${{ matrix.php }}
          wp: ${{ matrix.wp }}
          plugin: .
          run: ./vendor/bin/phpunit
```

### Post-merge tag dance

After PR 5 merges into a release that produces `v0.2.0`:

```bash
git tag -f v1 v0.2.0  # floating major tag per GitHub Actions convention
git push origin v1 --force
```

This is the only documented use of `--force` in the project; isolated to a ref pattern
unused by PR workflows.

### Commits

1. `feat(action): add composite GitHub Action for matrix CI`
2. `ci: add integration workflow validating the action against a fixture plugin`
3. `docs: document GitHub Actions usage with matrix example`

### Verification

- Internal: `.github/workflows/integration-example.yml` is green on the PR.
- External: create a throwaway public repo, pin `uses: iserter/wp-test-env@<sha>` before
  tagging, confirm green.

### Rollback

Delete the `v1` tag; individual releases remain intact.

---

## PR 6 — Part E: Playwright fixture export

**Branch:** `feat/playwright-fixture`
**Depends on:** PR 4 (ships on the same npm package).
**Blast radius:** small — new export surface only.

### File-level changes

| Path | Action | Notes |
|---|---|---|
| `playwright/fixtures.ts` | New | Exports `test` extended with `wpFixture` ({ baseURL, adminPage, wpCli() }). Reuses `tests/e2e/helpers/instances.ts` for discovery. |
| `playwright/index.ts` | New | Barrel re-export. |
| `package.json` | Edit | Add `"exports": { ".": "./bin/wp-test-env.js", "./playwright": "./playwright/index.ts" }` and `"peerDependencies": { "@playwright/test": "^1.50.0" }`. |
| `tsconfig.build.json` | New | Emits `.d.ts` + `.js` to `dist/playwright/` for publishing. |
| `examples/fixture-consumer/` | New | Full sample project consuming the fixture. |
| `docs/dev-guide/playwright-fixture.md` | New | Usage guide. |

### Commits

1. `feat(playwright): export wpFixture for consumer E2E tests`
2. `build: add tsconfig.build.json + compile step for the playwright export`
3. `docs(dev-guide): add Playwright fixture usage guide`

### Verification

```bash
npm run build
cd examples/fixture-consumer
npm i ../..
npx playwright install chromium
npx playwright test
# All tests pass against a running instance
```

### Rollback

Remove the `./playwright` subpath export in a patch release; consumers on older versions
are unaffected.

---

## Cross-Cutting Work

### CI hardening

- **`.github/workflows/ci.yml`** (added in PR 1, extended later):
  - `golden-compose` job: runs `tests/generate-compose.test.sh` on every PR.
  - `shellcheck` job: lints all `scripts/*.sh` to catch quoting regressions.
  - `integration` job (added in PR 5): boots one PHP+WP combo, installs
    `fixtures/example-plugin`, hits a health endpoint.

### Docs updates per PR

Every PR updates `README.md` incrementally; after PR 4 lands, insert the
"Already using `@wordpress/env`?" positioning box from
`improve-developer-experience.md` at the top of the README.

### Release cadence

- PR 0 — cut `v0.1.0`.
- PRs 1–3 merge individually, no interim release.
- After PR 4 merges (first npm-visible change), cut `v0.2.0-rc.1` for external smoke
  testing.
- After PRs 5–6 merge, cut `v0.2.0`.
- Tag floating `v1` for the Action.

### Commit-message hygiene

release-please depends on conventional commits. A `commitlint` pre-push hook would be
nice-to-have; skip for now (solo maintainer, low blast radius of a bad commit).

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `yq` not installed in user environment | Medium | Config file fails cryptically | Clear install-instructions error message in `load-config.sh`; fall back to env vars |
| macOS `realpath` vs Linux divergence breaks path resolution in Part A | Medium | Bind-mount points wrong | Portable `_abspath()` shim with three fallbacks; golden-file test runs on macOS + Linux CI |
| npm scope `@iserter` not owned | Low | Publish fails on first try | Verify before tagging; if taken, fall back to unscoped `wp-test-env-cli` or similar |
| GitHub Action composite-step clones this repo each run (slow) | Medium | CI cost for consumers | Acceptable for v0.2.0; future work: publish pre-built images to GHCR, action pulls instead of clone+build |
| Template-repo flag forgotten on GitHub | Low | Part B.2 half-working | Add to a release checklist in CONTRIBUTING.md |
| Action of breaking seeding default in Part F | Low | Surprise for long-time users | Default `SEED_WOOCOMMERCE=true`; call out prominently in CHANGELOG |

---

## Definition of Done

The full DX initiative is complete when:

- [ ] `v0.2.0` is tagged on GitHub with a complete auto-generated changelog.
- [ ] `npm install -g @iserter/wp-test-env && wp-test-env init 8.3 6.8` works from a
      fresh user's machine without cloning this repo.
- [ ] A consumer project can rely on `uses: iserter/wp-test-env@v1` in their CI and get
      green builds.
- [ ] The README opens with the "Already using wp-env?" positioning box.
- [ ] All six parts' acceptance criteria (from `improve-developer-experience.md`) are
      checked off.
- [ ] Zero existing user-visible behavior has changed when all new flags are left unset.
