import { APIRequestContext } from '@playwright/test';

export class WpApi {
  constructor(
    private request: APIRequestContext,
    private baseURL: string,
    private username: string = 'admin',
    private password: string = 'admin'
  ) {}

  private get auth() {
    return {
      Authorization: `Basic ${Buffer.from(`${this.username}:${this.password}`).toString('base64')}`,
    };
  }

  async getPosts(params: Record<string, string> = {}) {
    const query = new URLSearchParams(params).toString();
    const url = `${this.baseURL}/wp-json/wp/v2/posts${query ? '?' + query : ''}`;
    return this.request.get(url, { headers: this.auth });
  }

  async getCurrentUser() {
    return this.request.get(`${this.baseURL}/wp-json/wp/v2/users/me`, {
      headers: this.auth,
    });
  }

  async getWcOrders(params: Record<string, string> = {}) {
    const query = new URLSearchParams(params).toString();
    const url = `${this.baseURL}/wp-json/wc/v3/orders${query ? '?' + query : ''}`;
    return this.request.get(url, { headers: this.auth });
  }

  async getWcProducts(params: Record<string, string> = {}) {
    const query = new URLSearchParams(params).toString();
    const url = `${this.baseURL}/wp-json/wc/v3/products${query ? '?' + query : ''}`;
    return this.request.get(url, { headers: this.auth });
  }

  async getWcSystemStatus() {
    return this.request.get(`${this.baseURL}/wp-json/wc/v3/system_status`, {
      headers: this.auth,
    });
  }
}
