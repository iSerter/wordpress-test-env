import { test as base, expect } from '@playwright/test';
import { WP } from '../../helpers/selectors';

// Use a fresh context without stored auth for login tests
const test = base.extend({});

test.use({ storageState: { cookies: [], origins: [] } });

test.describe('WordPress: Admin Login', () => {
  test('can log in with valid credentials', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/wp-login.php`);
    await page.fill(WP.login.username, 'admin');
    await page.fill(WP.login.password, 'admin');
    await page.click(WP.login.submit);

    await page.waitForURL('**/wp-admin/**');
    await expect(page.locator(WP.dashboard.adminBar)).toBeVisible();
  });

  test('rejects invalid credentials', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/wp-login.php`);
    await page.fill(WP.login.username, 'admin');
    await page.fill(WP.login.password, 'wrongpassword');
    await page.click(WP.login.submit);

    await expect(page.locator(WP.login.error)).toBeVisible();
  });
});
