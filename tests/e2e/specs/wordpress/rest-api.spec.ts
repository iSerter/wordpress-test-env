import { test, expect } from '../../fixtures/wp-instance';

test.describe('WordPress: REST API', () => {
  test('GET /wp-json/wp/v2/posts returns 200', async ({ wpApi }) => {
    const response = await wpApi.getPosts();
    expect(response.ok()).toBeTruthy();
    const body = await response.json();
    expect(Array.isArray(body)).toBeTruthy();
  });

  test('GET /wp-json/wp/v2/users/me returns admin user', async ({ wpApi }) => {
    const response = await wpApi.getCurrentUser();
    expect(response.ok()).toBeTruthy();
    const user = await response.json();
    expect(user.slug).toBe('admin');
  });
});
