import { defineConfig } from '@playwright/test';
import { getWpProjects } from '@iserter/wp-test-env/playwright';

export default defineConfig({
    testDir: './tests',
    timeout: 30_000,
    fullyParallel: true,
    reporter: 'list',

    // Log into every running WP instance once before the test run.
    globalSetup: require.resolve('@iserter/wp-test-env/playwright/setup'),

    // One Playwright project per discovered instance; each gets a scoped
    // baseURL and a pre-populated storageState so `adminPage` is logged in.
    projects: getWpProjects(),
});
