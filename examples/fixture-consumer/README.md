# Fixture Consumer Example

A minimal project that consumes `@iserter/wp-test-env/playwright` to run
E2E tests against whichever WP instances happen to be running.

## Run it

```bash
# From the repo root, install + build the parent package first
npm install
npm run build

# Then install this example's deps (uses `file:../..`)
cd examples/fixture-consumer
npm install
npx playwright install chromium

# Ensure at least one WP instance is up
(cd ../.. && ./scripts/start.sh 8.3 6.8)

# Run the fixture tests
npx playwright test
```

## What this demonstrates

- `getWpProjects()` generates one Playwright project per running container.
- `globalSetup` logs into every instance once and caches the admin session.
- `test` / `expect` come from the fixture — `adminPage` is pre-authed.
- `wpCli` runs wp-cli inside the container for the current project.

## Using in your own project

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';
import { getWpProjects } from '@iserter/wp-test-env/playwright';

export default defineConfig({
    globalSetup: require.resolve('@iserter/wp-test-env/playwright/setup'),
    projects: getWpProjects(),
});
```

```ts
// tests/my-plugin.spec.ts
import { test, expect } from '@iserter/wp-test-env/playwright';

test('plugin settings page renders', async ({ adminPage }) => {
    await adminPage.goto('/wp-admin/admin.php?page=my-plugin');
    await expect(adminPage.getByText('My Plugin Settings')).toBeVisible();
});
```
