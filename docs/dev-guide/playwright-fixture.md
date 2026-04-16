# Playwright Fixture (`@iserter/wp-test-env/playwright`)

Write Playwright E2E tests against your plugin without reinventing instance
discovery, admin login, or wp-cli wrapping. This subpath export ships a
ready-made `test` fixture plus helpers for generating Playwright project
configs.

## Install

```bash
npm i -D @iserter/wp-test-env @playwright/test
npx playwright install chromium
```

`@playwright/test` is declared as an optional peer dependency — the fixture
only works if you're using Playwright, but the main `wp-test-env` CLI
doesn't require it.

## Wire it up

### `playwright.config.ts`

```ts
import { defineConfig } from '@playwright/test';
import { getWpProjects } from '@iserter/wp-test-env/playwright';

export default defineConfig({
    testDir: './tests',
    globalSetup: require.resolve('@iserter/wp-test-env/playwright/setup'),
    projects: getWpProjects(),
});
```

- `getWpProjects()` calls `docker ps` to discover running `wp-NN-NN`
  containers and returns one Playwright project per match, with `baseURL`
  and `storageState` configured per instance.
- `globalSetup` logs into every instance once (username/password = admin/admin
  by default) and writes session state to `.wp-auth/` in your CWD.

### Spec files

```ts
import { test, expect } from '@iserter/wp-test-env/playwright';

test('plugin settings page renders', async ({ adminPage }) => {
    await adminPage.goto('/wp-admin/admin.php?page=my-plugin');
    await expect(adminPage.getByText('My Plugin Settings')).toBeVisible();
});

test('shortcode option is set', async ({ wpCli }) => {
    const value = wpCli('option get my_plugin_mode');
    expect(value).toBe('active');
});
```

## Fixtures

| Name | Type | Notes |
|---|---|---|
| `adminPage` | `Page` | Same as Playwright's `page`, but the project's `storageState` loads the admin session. Navigate straight to `/wp-admin/...` URLs. |
| `wpCli` | `(args: string) => string` | Runs `wp <args>` inside the container for the current project. Returns stdout (trimmed). Throws on non-zero exit. |

## Helpers

| Export | Purpose |
|---|---|
| `test`, `expect` | Playwright primitives with `WpFixtures` merged in |
| `getRunningInstances()` | Raw list of discovered `WpInstance` objects |
| `getWpProjects(opts?)` | Playwright project configs, one per instance |
| `setupWpAuth(opts?)` | Login routine (use in your own globalSetup) |
| `globalSetup` | Default-export helper for `playwright.config.ts` |

### Explicit instance list

Override auto-discovery via the `TEST_INSTANCES` env var:

```bash
TEST_INSTANCES="8.3:6.8,8.5:7.0" npx playwright test
```

### Custom auth dir

```ts
// Keep auth state in a custom location
projects: getWpProjects({ authDir: '/tmp/my-plugin-auth' })
```

Pair with a matching `setupWpAuth({ authDir: '/tmp/my-plugin-auth' })` in
your `globalSetup`.

### Non-admin users

The default setup logs in as `admin/admin`. Pass credentials via options
and use your own globalSetup:

```ts
// my-setup.ts
import { setupWpAuth } from '@iserter/wp-test-env/playwright';
export default async () => {
    await setupWpAuth({ username: 'john', password: 'password' });
};
```

## Working example

See [`examples/fixture-consumer/`](../../examples/fixture-consumer/) for a
full, runnable project.
