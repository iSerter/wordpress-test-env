import { defineConfig } from '@playwright/test';
import * as path from 'path';
import { getRunningInstances } from './tests/e2e/helpers/instances';

const instances = getRunningInstances();

if (instances.length === 0) {
  console.warn(
    '⚠ No running WordPress instances detected. Start instances with ./scripts/start.sh'
  );
}

export default defineConfig({
  testDir: './tests/e2e/specs',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: [['html', { open: 'never' }], ['list']],
  timeout: 60_000,

  globalSetup: path.resolve(__dirname, 'tests/e2e/global-setup.ts'),

  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },

  projects: instances.map(({ php, wp, port, baseURL }) => ({
    name: `php${php}-wp${wp}`,
    use: {
      baseURL,
      storageState: path.resolve(
        __dirname,
        `tests/e2e/.auth/php${php}-wp${wp}.json`
      ),
    },
  })),
});
