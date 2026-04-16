import { test as base, expect, type Page } from '@playwright/test';
import { execSync } from 'child_process';

export interface WpFixtures {
    /**
     * Page with the admin session already loaded via the project's
     * `storageState`. Use it to navigate to `/wp-admin/...` URLs directly.
     */
    adminPage: Page;
    /**
     * Run a wp-cli command inside the container for the current project.
     * Returns stdout as a UTF-8 string. Throws on non-zero exit.
     *
     * Example: `wpCli('option get siteurl')` → `"http://localhost:8368"`
     */
    wpCli: (args: string) => string;
}

function serviceFromProject(projectName: string): string {
    const m = projectName.match(/^php(\d)\.(\d)-wp(\d)\.(\d+)$/);
    if (!m) {
        throw new Error(
            `wp-test-env: cannot derive container service from project name "${projectName}". ` +
            `Expected format "php<M>.<m>-wp<M>.<m>" (set by getWpProjects()).`
        );
    }
    return `wp-${m[1]}${m[2]}-${m[3]}${m[4]}`;
}

/**
 * Playwright `test` extended with wp-test-env fixtures. Import this instead
 * of @playwright/test in specs that need authenticated admin pages or
 * wp-cli access.
 */
export const test = base.extend<WpFixtures>({
    adminPage: async ({ page }, use) => {
        // The project's storageState loads the admin session automatically;
        // this fixture just re-exposes `page` under a clearer name.
        await use(page);
    },
    wpCli: async ({}, use, testInfo) => {
        const svc = serviceFromProject(testInfo.project.name);
        const fn = (args: string): string =>
            execSync(`docker compose exec -T --user www-data ${svc} wp ${args}`, {
                encoding: 'utf-8',
            }).trimEnd();
        await use(fn);
    },
});

export { expect };
