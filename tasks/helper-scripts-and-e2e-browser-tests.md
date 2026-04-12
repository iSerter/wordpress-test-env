# Task: Helper Scripts & E2E Browser Tests

**Phase:** 1.5 — Quality of Life & Validation
**Status:** Planning
**Depends on:** Phase 1 complete (Tasks 01–07)

## Objective

Add utility scripts that streamline day-to-day plugin testing workflows, and introduce a Playwright-based E2E test suite that can verify WordPress + WooCommerce functionality across all running instances.

---

## Part A: Helper Scripts

New scripts in `scripts/`, following existing conventions (sourcing `config.sh`, accepting optional `[php_version wp_version]` filter args, color-coded logging).

### A1. `scripts/logs.sh` — View container logs

Stream or tail Docker logs for one or all instances.

```
./scripts/logs.sh 8.3 6.8          # tail logs for one instance
./scripts/logs.sh                   # tail logs for all running instances
./scripts/logs.sh 8.3 6.8 --follow # stream live
```

Implementation: Thin wrapper around `docker compose logs` with `--tail` and optional `--follow` flag.

### A2. `scripts/wp.sh` — Run arbitrary WP-CLI commands

Pass-through to `wp` inside a container. Saves typing the full `docker compose exec` invocation.

```
./scripts/wp.sh 8.3 6.8 plugin list
./scripts/wp.sh 8.3 6.8 option get siteurl
./scripts/wp.sh 8.3 6.8 db query "SELECT count(*) FROM wp_posts"
```

Implementation: Uses the existing `wp_exec` helper from `config.sh`. First two positional args are PHP+WP versions; the rest are forwarded to WP-CLI.

### A3. `scripts/install-plugin.sh` — Install a plugin from slug or zip

Install a plugin on one or all instances by WordPress.org slug or local/remote zip path.

```
./scripts/install-plugin.sh query-monitor               # slug, all instances
./scripts/install-plugin.sh ./my-plugin.zip 8.3 6.8     # zip, one instance
./scripts/install-plugin.sh query-monitor 8.3 6.8       # slug, one instance
```

Implementation: Detects whether the first arg is a file path (contains `/` or ends in `.zip`) vs. a slug. For zips, `docker cp` the file into the container then `wp plugin install`. For slugs, `wp plugin install --activate`.

### A4. `scripts/health-check.sh` — Verify instances are healthy

Hit each instance's homepage and WP REST API (`/wp-json/wp/v2/settings` or `/wp-json/wc/v3/system_status`) and report HTTP status codes. Useful as a smoke test after `init.sh` or `start.sh`.

```
./scripts/health-check.sh              # check all
./scripts/health-check.sh 8.3 6.8      # check one
```

Implementation: `curl -s -o /dev/null -w "%{http_code}"` against `localhost:{port}` and `localhost:{port}/wp-json/wp/v2/`. Reports a table with pass/fail per instance.

### A5. `scripts/export-db.sh` / `scripts/import-db.sh` — Database snapshots

Export and import a single instance's database for quick save/restore during testing.

```
./scripts/export-db.sh 8.3 6.8                     # → snapshots/wp_83_68.sql
./scripts/import-db.sh 8.3 6.8 snapshots/wp_83_68.sql
```

Implementation: `wp db export` / `wp db import` via `wp_exec`. Snapshots stored in `snapshots/` directory (gitignored).

### A6. `scripts/open.sh` — Open instance in browser

Open one or more instances in the default browser.

```
./scripts/open.sh 8.3 6.8            # opens http://localhost:8368/wp-admin
./scripts/open.sh 8.3 6.8 --front    # opens http://localhost:8368
```

Implementation: Uses `open` (macOS) / `xdg-open` (Linux) with the computed port.

---

## Part B: E2E Browser Tests (Playwright)

### Why Playwright

- First-class multi-browser support (Chromium, Firefox, WebKit)
- Built-in test runner with parallel execution
- Auto-waiting, network interception, screenshots on failure
- Can be driven from a simple config — no heavy framework needed
- TypeScript support out of the box

### B1. Project Setup

```
tests/
  e2e/
    playwright.config.ts      # config: base URL parameterized, projects per instance
    global-setup.ts           # authenticate once, save storage state
    fixtures/
      wp-instance.ts          # custom fixture: provides baseURL + auth for an instance
    specs/
      wordpress/
        admin-login.spec.ts   # WP admin login works
        dashboard.spec.ts     # dashboard loads without PHP errors
        rest-api.spec.ts      # REST API responds with expected data
      woocommerce/
        storefront.spec.ts    # shop page loads, products visible
        cart.spec.ts          # add to cart, view cart
        checkout.spec.ts      # complete a checkout with COD
        admin-orders.spec.ts  # order appears in WP admin
      smoke/
        health.spec.ts        # all instances return 200
    helpers/
      wp-api.ts               # REST API helper (create/get orders, products, etc.)
      selectors.ts            # shared CSS/data-testid selectors for WP/WC pages
```

Root-level files:
- `package.json` — devDependencies: `@playwright/test`
- `tsconfig.json` — minimal config for the test files
- `.gitignore` update — add `node_modules/`, `test-results/`, `playwright-report/`

### B2. Configuration Strategy

The key challenge is running the same test suite against multiple WordPress instances (different ports). Playwright's **projects** feature handles this natively:

```ts
// playwright.config.ts
const instances = getRunningInstances(); // reads from env or detects running containers

export default defineConfig({
  projects: instances.map(({ php, wp, port }) => ({
    name: `php${php}-wp${wp}`,
    use: {
      baseURL: `http://localhost:${port}`,
      storageState: `tests/e2e/.auth/php${php}-wp${wp}.json`,
    },
  })),
});
```

A helper script or `global-setup.ts` detects which containers are running (via `docker ps` or the port scheme from `config.sh`) and generates the project list dynamically. Tests only run against instances that are currently up.

### B3. Authentication

`global-setup.ts` logs in to `/wp-login.php` for each running instance and saves the authenticated browser state (cookies) to a JSON file. All subsequent tests reuse this state — no repeated logins.

### B4. Test Specs — Details

#### WordPress Core

| Test | What it verifies |
|------|-----------------|
| `admin-login.spec.ts` | Navigate to `/wp-login.php`, submit credentials, verify redirect to dashboard |
| `dashboard.spec.ts` | Dashboard loads, no PHP fatal/warning notices visible, key widgets present |
| `rest-api.spec.ts` | `GET /wp-json/wp/v2/posts` returns 200, `GET /wp-json/wp/v2/users/me` returns admin user |

#### WooCommerce

| Test | What it verifies |
|------|-----------------|
| `storefront.spec.ts` | `/shop` loads, at least one product visible, product links work |
| `cart.spec.ts` | Add a product to cart via the shop page, cart page shows correct item |
| `checkout.spec.ts` | Fill checkout form with test data, select COD, place order, see confirmation |
| `admin-orders.spec.ts` | Navigate to WooCommerce → Orders in admin, verify the order placed above exists |

#### Smoke

| Test | What it verifies |
|------|-----------------|
| `health.spec.ts` | Every running instance returns HTTP 200 on `/` and `/wp-json/` |

### B5. Running the Tests

```bash
# Run all E2E tests against all running instances
npx playwright test

# Run against a specific instance
npx playwright test --project="php8.3-wp6.8"

# Run only WooCommerce tests
npx playwright test tests/e2e/specs/woocommerce/

# Run with UI mode (interactive debugging)
npx playwright test --ui

# Run with HTML report
npx playwright test --reporter=html
```

Convenience script:
```bash
# scripts/test.sh — wrapper that checks containers are up, then runs Playwright
./scripts/test.sh                    # all instances
./scripts/test.sh 8.3 6.8           # single instance
./scripts/test.sh --smoke            # smoke tests only
```

### B6. `scripts/test.sh` — Test Runner Wrapper

Convenience wrapper that:
1. Checks that `node_modules` are installed (runs `npm install` if not)
2. Checks that Playwright browsers are installed (runs `npx playwright install` if not)
3. Detects running instances (or uses the provided PHP+WP filter)
4. Sets environment variables (`TEST_INSTANCES` with port list)
5. Runs `npx playwright test` with the appropriate flags

---

## Implementation Order

| Step | Item | Depends on | Effort |
|------|------|------------|--------|
| 1 | `scripts/wp.sh` | — | Small |
| 2 | `scripts/logs.sh` | — | Small |
| 3 | `scripts/open.sh` | — | Small |
| 4 | `scripts/health-check.sh` | — | Small |
| 5 | `scripts/install-plugin.sh` | — | Medium |
| 6 | `scripts/export-db.sh` + `scripts/import-db.sh` | — | Medium |
| 7 | Playwright project setup (`package.json`, config, fixtures) | — | Medium |
| 8 | Auth global setup + smoke tests | Step 7 | Medium |
| 9 | WordPress core E2E specs | Step 8 | Medium |
| 10 | WooCommerce E2E specs | Step 8 | Medium–Large |
| 11 | `scripts/test.sh` wrapper | Step 7 | Small |
| 12 | README updates | All above | Small |

Steps 1–6 are independent and can be implemented in parallel.
Steps 7–8 must be sequential. Steps 9–11 can proceed in parallel after step 8.

---

## Acceptance Criteria

### Helper Scripts
- [ ] Each script follows existing conventions: sources `config.sh`, accepts `[php wp]` filter, uses color logging
- [ ] Each script has `--help` output
- [ ] `scripts/health-check.sh` exits non-zero if any instance fails (CI-friendly)
- [ ] `scripts/wp.sh` correctly forwards all args to WP-CLI
- [ ] `scripts/install-plugin.sh` handles both slugs and zip files
- [ ] `snapshots/` directory is gitignored

### E2E Tests
- [ ] `npm install && npx playwright test` works from repo root after instances are running
- [ ] Tests dynamically discover running instances — no hardcoded ports
- [ ] Authentication state is cached per instance (login happens once in global setup)
- [ ] All specs pass on at least PHP 8.3 + WP 6.8 (reference instance)
- [ ] Screenshots captured on test failure (stored in `test-results/`)
- [ ] `scripts/test.sh` provides a zero-config entry point
- [ ] Tests can target a single instance via `--project` or via `scripts/test.sh 8.3 6.8`
