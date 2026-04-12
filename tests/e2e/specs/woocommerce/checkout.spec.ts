import { test, expect } from '../../fixtures/wp-instance';
import { WC } from '../../helpers/selectors';

test.describe('WooCommerce: Checkout', () => {
  test('can complete a checkout with Cash on Delivery', async ({ page }) => {
    // Add a product to cart via shop page
    await page.goto('/shop/');
    const ajaxBtn = page.locator(WC.shop.addToCart).first();
    const isAjax = await ajaxBtn.isVisible().catch(() => false);

    if (isAjax) {
      await ajaxBtn.click();
      await page.waitForTimeout(2000);
    } else {
      await page.locator(WC.shop.productLink).first().click();
      await page.waitForLoadState('domcontentloaded');
      await page.locator('button[name="add-to-cart"], .single_add_to_cart_button').first().click();
      await page.waitForLoadState('domcontentloaded');
    }

    // Navigate to checkout
    await page.goto('/checkout/');

    // Fill billing details
    await page.fill(WC.checkout.firstName, 'Test');
    await page.fill(WC.checkout.lastName, 'Buyer');
    await page.fill(WC.checkout.address, '123 Test Street');
    await page.fill(WC.checkout.city, 'Test City');
    await page.fill(WC.checkout.postcode, '10001');
    await page.fill(WC.checkout.phone, '555-0100');
    await page.fill(WC.checkout.email, 'test@example.com');

    // Select Cash on Delivery if not already selected
    const codRadio = page.locator('#payment_method_cod');
    if (await codRadio.isVisible().catch(() => false)) {
      await codRadio.check();
    }

    // Place order
    await page.locator(WC.checkout.placeOrder).click();

    // Verify order confirmation page
    await expect(
      page.locator(WC.checkout.orderReceived)
    ).toBeVisible({ timeout: 30_000 });
  });
});
