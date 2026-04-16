// Public entry point for the @iserter/wp-test-env/playwright subpath export.
// See docs/dev-guide/playwright-fixture.md for usage.

export { test, expect, type WpFixtures } from './fixtures';
export {
    getRunningInstances,
    getWpProjects,
    type WpInstance,
    type GetWpProjectsOptions,
} from './projects';
export { setupWpAuth, type SetupWpAuthOptions } from './auth';
export { default as globalSetup } from './setup';
