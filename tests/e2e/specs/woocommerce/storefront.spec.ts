import { test, expect } from '../../fixtures/wp-instance';
import { WC } from '../../helpers/selectors';

test.describe('WooCommerce: Storefront', () => {
  test('shop page loads with products', async ({ page }) => {
    await page.goto('/shop/');
    const products = page.locator(WC.shop.products);
    await expect(products.first()).toBeVisible({ timeout: 15_000 });
    expect(await products.count()).toBeGreaterThan(0);
  });

  test('product link navigates to single product', async ({ page }) => {
    await page.goto('/shop/');
    const firstProduct = page.locator(WC.shop.productLink).first();
    await expect(firstProduct).toBeVisible();

    const href = await firstProduct.getAttribute('href');
    expect(href).toBeTruthy();

    await firstProduct.click();
    await page.waitForLoadState('domcontentloaded');

    // Single product page should have an add-to-cart button or product summary
    const addToCart = page.locator('button[name="add-to-cart"], .single_add_to_cart_button');
    const productSummary = page.locator('.product, .summary');
    const isProduct = await addToCart.isVisible().catch(() => false) ||
                      await productSummary.isVisible().catch(() => false);
    expect(isProduct).toBeTruthy();
  });
});
