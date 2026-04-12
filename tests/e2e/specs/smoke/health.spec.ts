import { test, expect } from '../../fixtures/wp-instance';

test.describe('Smoke: Health Check', () => {
  test('homepage returns HTTP 200', async ({ request, baseURL }) => {
    const response = await request.get(`${baseURL}/`);
    expect(response.status()).toBeLessThan(400);
  });

  test('REST API root returns HTTP 200', async ({ request, baseURL }) => {
    const response = await request.get(`${baseURL}/wp-json/wp/v2/`);
    expect(response.ok()).toBeTruthy();
  });

  test('WP admin loads', async ({ page }) => {
    await page.goto('/wp-admin/');
    await expect(page).toHaveURL(/wp-admin/);
  });
});
