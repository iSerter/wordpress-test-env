import { chromium } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { getRunningInstances, type WpInstance } from './projects';

export interface SetupWpAuthOptions {
    /** Directory to write storageState JSON files. Default: `<cwd>/.wp-auth`. */
    authDir?: string;
    /** Admin username. Default: admin. */
    username?: string;
    /** Admin password. Default: admin. */
    password?: string;
    /** Reuse stored auth younger than this (ms). Default: 1 hour. */
    maxAge?: number;
    /** Override instance discovery (useful for tests). */
    instances?: WpInstance[];
}

/**
 * Log into every running WP instance's /wp-login.php and persist the
 * session to a storageState file per instance. Idempotent and cache-aware.
 *
 * Intended to be called from your Playwright `globalSetup`.
 */
export async function setupWpAuth(opts: SetupWpAuthOptions = {}): Promise<void> {
    const authDir = opts.authDir ?? path.resolve(process.cwd(), '.wp-auth');
    const username = opts.username ?? 'admin';
    const password = opts.password ?? 'admin';
    const maxAge = opts.maxAge ?? 3_600_000;

    const instances = opts.instances ?? getRunningInstances();
    if (instances.length === 0) {
        throw new Error(
            'wp-test-env: no running WordPress instances found. ' +
            'Start them first (e.g. `npx wp-test-env start 8.3 6.8`).'
        );
    }

    fs.mkdirSync(authDir, { recursive: true });
    const browser = await chromium.launch();

    try {
        for (const inst of instances) {
            const storageFile = path.join(authDir, `php${inst.php}-wp${inst.wp}.json`);

            if (fs.existsSync(storageFile)) {
                const ageMs = Date.now() - fs.statSync(storageFile).mtimeMs;
                if (ageMs < maxAge) continue;
            }

            const context = await browser.newContext();
            const page = await context.newPage();
            try {
                await page.goto(`${inst.baseURL}/wp-login.php`, { timeout: 30_000 });
                await page.fill('#user_login', username);
                await page.fill('#user_pass', password);
                await page.click('#wp-submit');
                await page.waitForURL('**/wp-admin/**', { timeout: 15_000 });
                await context.storageState({ path: storageFile });
            } finally {
                await context.close();
            }
        }
    } finally {
        await browser.close();
    }
}
