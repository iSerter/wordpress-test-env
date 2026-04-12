import { test as base } from '@playwright/test';
import { WpApi } from '../helpers/wp-api';

type WpFixtures = {
  wpApi: WpApi;
  instanceInfo: { php: string; wp: string; port: string };
};

export const test = base.extend<WpFixtures>({
  wpApi: async ({ request, baseURL }, use) => {
    const api = new WpApi(request, baseURL!);
    await use(api);
  },

  instanceInfo: async ({ baseURL }, use) => {
    // Extract version info from the baseURL port
    const url = new URL(baseURL!);
    const port = url.port;
    // Port format: {php_major}{php_minor}{wp_major}{wp_minor}
    const php = `${port[0]}.${port[1]}`;
    const wp = `${port[2]}.${port.slice(3)}`;
    await use({ php, wp, port });
  },
});

export { expect } from '@playwright/test';
