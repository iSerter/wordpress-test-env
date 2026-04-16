import { execSync } from 'child_process';
import * as path from 'path';

export interface WpInstance {
    php: string;
    wp: string;
    port: string;
    service: string;
    baseURL: string;
}

/**
 * Discover WordPress test-env instances currently running on the host.
 *
 * Resolution order:
 *   1. TEST_INSTANCES env var, format "8.3:6.8,8.5:7.0" — explicit override
 *   2. `docker ps` filtered on the wp-NN-NN naming convention
 *
 * Returns an empty array if neither source yields matches. Consumers should
 * surface a helpful error in that case (e.g. "did you run `scripts/start.sh`?").
 */
export function getRunningInstances(): WpInstance[] {
    const envInstances = process.env.TEST_INSTANCES;
    if (envInstances) {
        return parseInstanceList(envInstances);
    }

    try {
        const output = execSync(
            'docker ps --filter "name=wp-" --format "{{.Names}}"',
            { encoding: 'utf-8', timeout: 10_000 }
        );
        return parseDockerOutput(output);
    } catch {
        return [];
    }
}

function parseDockerOutput(output: string): WpInstance[] {
    const instances: WpInstance[] = [];
    for (const line of output.trim().split('\n').filter(Boolean)) {
        const m = line.match(/^wp-(\d)(\d)-(\d)(\d+)$/);
        if (!m) continue;
        instances.push(toInstance(m[1], m[2], m[3], m[4]));
    }
    return instances.sort((a, b) => a.port.localeCompare(b.port));
}

function parseInstanceList(envValue: string): WpInstance[] {
    return envValue
        .split(',')
        .map((pair) => pair.trim())
        .filter(Boolean)
        .map((pair) => {
            const [php, wp] = pair.split(':');
            const [pMaj, pMin] = php.split('.');
            const [wMaj, wMin] = wp.split('.');
            return toInstance(pMaj, pMin, wMaj, wMin);
        });
}

function toInstance(pMaj: string, pMin: string, wMaj: string, wMin: string): WpInstance {
    const php = `${pMaj}.${pMin}`;
    const wp = `${wMaj}.${wMin}`;
    const port = `${pMaj}${pMin}${wMaj}${wMin}`;
    return {
        php,
        wp,
        port,
        service: `wp-${pMaj}${pMin}-${wMaj}${wMin}`,
        baseURL: `http://localhost:${port}`,
    };
}

export interface GetWpProjectsOptions {
    /** Directory where per-instance auth state is persisted. Default: `<cwd>/.wp-auth` */
    authDir?: string;
    /** Override the storageState filename pattern. Default: `php<php>-wp<wp>.json`. */
    storageStateName?: (instance: WpInstance) => string;
}

/**
 * Build a Playwright `projects` array — one project per running instance —
 * with `baseURL` and `storageState` pre-wired. Pair with the exported
 * `globalSetup` to populate the storage states.
 */
export function getWpProjects(opts: GetWpProjectsOptions = {}) {
    const authDir = opts.authDir ?? path.resolve(process.cwd(), '.wp-auth');
    const nameFor = opts.storageStateName ?? ((i: WpInstance) => `php${i.php}-wp${i.wp}.json`);

    return getRunningInstances().map((inst) => ({
        name: `php${inst.php}-wp${inst.wp}`,
        use: {
            baseURL: inst.baseURL,
            storageState: path.join(authDir, nameFor(inst)),
        },
        metadata: {
            wp: inst,
        },
    }));
}
