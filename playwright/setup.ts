// Default-export helper suitable for Playwright's `globalSetup`:
//
//   // playwright.config.ts
//   import { defineConfig } from '@playwright/test';
//   import { getWpProjects } from '@iserter/wp-test-env/playwright';
//   export default defineConfig({
//     globalSetup: require.resolve('@iserter/wp-test-env/playwright/setup'),
//     projects: getWpProjects(),
//   });

import { setupWpAuth } from './auth';

export default async function globalSetup(): Promise<void> {
    await setupWpAuth();
}
