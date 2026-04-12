import { test, expect } from '../../fixtures/wp-instance';
import { WP } from '../../helpers/selectors';

test.describe('WordPress: Dashboard', () => {
  test('dashboard loads without PHP errors', async ({ page }) => {
    await page.goto('/wp-admin/');

    // Admin bar should be visible
    await expect(page.locator(WP.dashboard.adminBar)).toBeVisible();

    // No PHP fatal errors on the page
    const content = await page.content();
    expect(content).not.toContain('Fatal error');
    expect(content).not.toContain('Parse error');
  });

  test('admin menu is present', async ({ page }) => {
    await page.goto('/wp-admin/');
    await expect(page.locator(WP.admin.menu)).toBeVisible();
  });

  test('WooCommerce menu item exists', async ({ page }) => {
    await page.goto('/wp-admin/');
    await expect(
      page.locator('#adminmenu a[href*="woocommerce"]').first()
    ).toBeVisible();
  });
});
