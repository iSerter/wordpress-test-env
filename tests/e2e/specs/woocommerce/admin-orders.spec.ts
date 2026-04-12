import { test, expect } from '../../fixtures/wp-instance';

test.describe('WooCommerce: Admin Orders', () => {
  test('orders page loads in WP admin', async ({ page }) => {
    // Navigate to WooCommerce orders
    await page.goto('/wp-admin/admin.php?page=wc-orders');

    // Check for orders table or HPOS orders page
    const ordersTable = page.locator('.wp-list-table, .woocommerce-orders-table, #woocommerce-orders-table');
    const ordersWrap = page.locator('.wrap');

    await expect(ordersWrap).toBeVisible();

    // Page should not have PHP errors
    const content = await page.content();
    expect(content).not.toContain('Fatal error');
  });

  test('seeded orders are visible', async ({ page }) => {
    await page.goto('/wp-admin/admin.php?page=wc-orders');

    // There should be at least some orders (seeded 10 via seed-data.sh)
    const rows = page.locator('.wp-list-table tbody tr, .woocommerce-orders-table tbody tr');
    // Wait for the table to load
    await page.waitForLoadState('domcontentloaded');

    const count = await rows.count();
    expect(count).toBeGreaterThan(0);
  });
});
