# E2E Browser Tests

Playwright-based end-to-end tests that verify WordPress and WooCommerce functionality across all running instances.

## Prerequisites

- Node.js 18+ and npm
- Running WordPress instance(s) via `./scripts/start.sh`

## Quick Start

```bash
# Option A: Use the convenience wrapper (handles all setup)
./scripts/test.sh

# Option B: Manual setup
npm install
npx playwright install chromium
npx playwright test
```

## Project Structure

```
playwright.config.ts                    # Playwright configuration
tests/e2e/
  global-setup.ts                       # Authenticates against all running instances
  fixtures/
    wp-instance.ts                      # Custom test fixtures (wpApi, instanceInfo)
  helpers/
    instances.ts                        # Discovers running Docker instances
    selectors.ts                        # Shared CSS selectors for WP/WC pages
    wp-api.ts                           # REST API helper class
  specs/
    smoke/
      health.spec.ts                    # HTTP health checks
    wordpress/
      admin-login.spec.ts              # Login form (valid + invalid credentials)
      dashboard.spec.ts                # Dashboard loads without PHP errors
      rest-api.spec.ts                 # REST API returns expected data
    woocommerce/
      storefront.spec.ts               # Shop page, product listing
      cart.spec.ts                     # Add to cart flow
      checkout.spec.ts                 # Full checkout with COD
      admin-orders.spec.ts             # Orders visible in WP admin
  .auth/                               # Auto-generated auth state (gitignored)
```

## Running Tests

### Using `scripts/test.sh`

```bash
# All tests, all running instances
./scripts/test.sh

# All tests, single instance
./scripts/test.sh 8.3 6.8

# Smoke tests only
./scripts/test.sh --smoke

# Pass extra Playwright flags
./scripts/test.sh -- --headed
./scripts/test.sh 8.3 6.8 -- --debug
```

### Using Playwright directly

```bash
# All tests
npx playwright test

# Specific instance
npx playwright test --project="php8.3-wp6.8"

# Specific test file
npx playwright test tests/e2e/specs/woocommerce/checkout.spec.ts

# Interactive UI mode
npx playwright test --ui

# Headed mode (watch the browser)
npx playwright test --headed

# Generate HTML report
npx playwright test --reporter=html
npx playwright show-report
```

### npm scripts

```bash
npm test                  # all tests
npm run test:smoke        # smoke tests only
npm run test:wp           # WordPress core tests
npm run test:wc           # WooCommerce tests
npm run test:ui           # interactive UI mode
npm run test:report       # open last HTML report
```

## How It Works

### Dynamic Instance Discovery

The test suite automatically discovers which WordPress instances are currently running by inspecting Docker containers. No hardcoded ports or configuration needed.

You can also set the `TEST_INSTANCES` environment variable to override discovery:

```bash
TEST_INSTANCES="8.3:6.8,8.4:7.0" npx playwright test
```

### Authentication

`global-setup.ts` runs before all tests. It logs in to each running instance's `wp-login.php` and saves the authenticated browser state (cookies) to `tests/e2e/.auth/`. All subsequent tests reuse this cached state — no repeated logins. Auth state is refreshed if older than 1 hour.

### Playwright Projects

Each running instance becomes a Playwright "project". When you run tests, every spec is executed against every running instance. This means a single `npx playwright test` covers all PHP/WP combinations simultaneously.

### Custom Fixtures

The `wp-instance` fixture provides:

- **`wpApi`**: A `WpApi` instance for making authenticated REST API calls
- **`instanceInfo`**: `{ php, wp, port }` extracted from the instance's base URL

```ts
import { test, expect } from '../../fixtures/wp-instance';

test('example', async ({ wpApi, instanceInfo }) => {
  console.log(`Testing PHP ${instanceInfo.php} + WP ${instanceInfo.wp}`);
  const response = await wpApi.getPosts();
  expect(response.ok()).toBeTruthy();
});
```

## Writing New Tests

1. Place spec files under `tests/e2e/specs/` in the appropriate subdirectory
2. Import from `../../fixtures/wp-instance` for WP-aware fixtures, or from `@playwright/test` for vanilla Playwright
3. Use selectors from `helpers/selectors.ts` — add new selectors there rather than hardcoding in specs
4. Tests should be independent — each test should not depend on state from another test
5. Use `page.goto('/relative-path/')` — the `baseURL` is set per-project automatically

## Test Artifacts

On failure, Playwright captures:

- **Screenshots**: `test-results/` directory
- **Traces**: Available on first retry (use `npx playwright show-trace <trace.zip>`)

All artifacts are gitignored.

## Troubleshooting

**"No running WordPress instances detected"**: Start instances with `./scripts/start.sh` before running tests.

**Auth failures**: Delete `tests/e2e/.auth/` and re-run. The global setup will create fresh auth state.

**Timeout errors**: WooCommerce pages can be slow on first load. Increase `timeout` in `playwright.config.ts` if needed.

**Selector mismatches**: WooCommerce's HTML structure varies between versions. If a selector fails on a specific WP/WC version, check the actual page structure and update `helpers/selectors.ts` with version-compatible selectors.
