import { execSync } from 'child_process';

export interface WpInstance {
  php: string;
  wp: string;
  port: string;
  service: string;
  baseURL: string;
}

/**
 * Discover running WordPress instances by checking Docker containers.
 * Matches container names like "wp-83-68" and extracts version info.
 */
export function getRunningInstances(): WpInstance[] {
  const envInstances = process.env.TEST_INSTANCES;
  if (envInstances) {
    return parseInstanceList(envInstances);
  }

  try {
    const output = execSync(
      'docker ps --filter "name=wp-" --format "{{.Names}}\t{{.Ports}}"',
      { encoding: 'utf-8', timeout: 10_000 }
    );
    return parseDockerOutput(output);
  } catch {
    return [];
  }
}

function parseDockerOutput(output: string): WpInstance[] {
  const instances: WpInstance[] = [];
  const lines = output.trim().split('\n').filter(Boolean);

  for (const line of lines) {
    const [name] = line.split('\t');
    // Match wp-{php}{wp} pattern, e.g. wp-83-68
    const match = name.match(/^wp-(\d)(\d)-(\d)(\d+)$/);
    if (!match) continue;

    const php = `${match[1]}.${match[2]}`;
    const wp = `${match[3]}.${match[4]}`;
    const port = `${match[1]}${match[2]}${match[3]}${match[4]}`;
    const service = name;

    instances.push({
      php,
      wp,
      port,
      service,
      baseURL: `http://localhost:${port}`,
    });
  }

  return instances.sort((a, b) => a.port.localeCompare(b.port));
}

/**
 * Parse TEST_INSTANCES env var. Format: "8.3:6.8,8.4:7.0"
 */
function parseInstanceList(envValue: string): WpInstance[] {
  return envValue.split(',').map((pair) => {
    const [php, wp] = pair.trim().split(':');
    const phpSlug = php.replace('.', '');
    const wpSlug = wp.replace('.', '');
    const port = `${phpSlug}${wpSlug}`;
    return {
      php,
      wp,
      port,
      service: `wp-${phpSlug}-${wpSlug}`,
      baseURL: `http://localhost:${port}`,
    };
  });
}
