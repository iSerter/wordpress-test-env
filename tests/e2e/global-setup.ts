import { chromium, FullConfig } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { getRunningInstances } from './helpers/instances';
import { WP } from './helpers/selectors';

const AUTH_DIR = path.join(__dirname, '.auth');

async function globalSetup(config: FullConfig) {
  fs.mkdirSync(AUTH_DIR, { recursive: true });

  const instances = getRunningInstances();
  if (instances.length === 0) {
    throw new Error(
      'No running WordPress instances found. Start instances with ./scripts/start.sh first.'
    );
  }

  const browser = await chromium.launch();

  for (const instance of instances) {
    const storageFile = path.join(AUTH_DIR, `php${instance.php}-wp${instance.wp}.json`);

    // Skip if auth state was saved recently (within 1 hour)
    if (fs.existsSync(storageFile)) {
      const stats = fs.statSync(storageFile);
      const ageMs = Date.now() - stats.mtimeMs;
      if (ageMs < 3600_000) continue;
    }

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      await page.goto(`${instance.baseURL}/wp-login.php`, { timeout: 30_000 });
      await page.fill(WP.login.username, 'admin');
      await page.fill(WP.login.password, 'admin');
      await page.click(WP.login.submit);
      await page.waitForURL('**/wp-admin/**', { timeout: 15_000 });
      await context.storageState({ path: storageFile });
    } catch (error) {
      console.warn(`⚠ Auth failed for ${instance.service}: ${error}`);
    } finally {
      await context.close();
    }
  }

  await browser.close();
}

export default globalSetup;
