import { test, expect } from '../../fixtures/wp-instance';
import { WC } from '../../helpers/selectors';

test.describe('WooCommerce: Cart', () => {
  test('can add a product to the cart and view it', async ({ page }) => {
    // Go to shop
    await page.goto('/shop/');

    // Try AJAX add-to-cart button first (simple products on archive)
    const ajaxBtn = page.locator(WC.shop.addToCart).first();
    const isAjax = await ajaxBtn.isVisible().catch(() => false);

    if (isAjax) {
      await ajaxBtn.click();
      // Wait for AJAX to complete (button changes or cart widget updates)
      await page.waitForTimeout(2000);
    } else {
      // Navigate to first product and add from there
      await page.locator(WC.shop.productLink).first().click();
      await page.waitForLoadState('domcontentloaded');
      await page.locator('button[name="add-to-cart"], .single_add_to_cart_button').first().click();
      await page.waitForLoadState('domcontentloaded');
    }

    // Go to cart
    await page.goto('/cart/');

    // Cart should contain at least one item
    const cartItems = page.locator(WC.cart.item);
    await expect(cartItems.first()).toBeVisible({ timeout: 10_000 });
    expect(await cartItems.count()).toBeGreaterThanOrEqual(1);
  });
});
