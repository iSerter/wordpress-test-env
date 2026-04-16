import { test, expect } from '@iserter/wp-test-env/playwright';

test('admin dashboard loads', async ({ adminPage }) => {
    await adminPage.goto('/wp-admin/');
    await expect(adminPage).toHaveURL(/\/wp-admin\/?$/);
    await expect(adminPage.locator('#wpadminbar')).toBeVisible();
});

test('wpCli returns siteurl matching baseURL', async ({ wpCli, baseURL }) => {
    const siteurl = wpCli('option get siteurl');
    expect(siteurl).toBe(baseURL);
});
