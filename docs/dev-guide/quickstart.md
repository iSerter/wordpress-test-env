# Quickstart

Zero → working test environment in under five minutes. Pick whichever
entry point matches your workflow.

## Prerequisites

- **Docker** + Docker Compose v2 (check: `docker compose version`)
- **Node 18+** — only if you use the npm wrapper or the Playwright fixture
- A free port in the 8100–8600 range (check: `lsof -i :8368`)

---

## Path 1 — `npx` from your plugin directory (fastest for plugin devs)

```bash
cd /path/to/your-plugin
npx @iserter/wp-test-env init 8.3 6.8
```

That's it. The wrapper auto-detects that your CWD is a WordPress plugin
(looks for a `.php` file with a `Plugin Name:` header) and bind-mounts it
into the container. Open `http://localhost:8368/wp-admin` — login is
`admin` / `admin`.

Edits to your plugin files reflect live in the container — no rebuild.

## Path 2 — Use as a GitHub template

1. Visit https://github.com/iSerter/wordpress-test-env and click **Use this
   template**. You now own a repo whose starter `wp-test-env.yml.example`
   is pre-wired for a `./plugin/` mount target.
2. Clone your new repo, create the mount target, and boot:

   ```bash
   cp wp-test-env.yml.example wp-test-env.yml
   ln -s /path/to/your-plugin plugin    # or: mkdir plugin && cp -R … plugin/
   ./scripts/init.sh
   ./scripts/activate-mounted-plugins.sh
   ```

See [`.github/TEMPLATE.md`](../../.github/TEMPLATE.md) for the full
template-repo walkthrough.

## Path 3 — Classic clone (for contributing or extensive customization)

```bash
git clone https://github.com/iSerter/wordpress-test-env.git
cd wordpress-test-env
cp .env.example .env

# One instance (fast — ~2 min first run)
./scripts/init.sh 8.3 6.8

# Or the full 33-combo matrix (takes a while)
./scripts/init.sh
```

---

## Verify it's working

```bash
# Which instances are up and on which ports
./scripts/status.sh

# Open a browser to an instance
./scripts/open.sh 8.3 6.8

# Run any WP-CLI command inside a container
./scripts/wp.sh 8.3 6.8 plugin list
./scripts/wp.sh 8.3 6.8 option get siteurl
```

## Bind-mount your plugin (classic flow)

If you went with Path 3 (clone) and want live plugin development, add this
to `.env`:

```bash
PLUGIN_PATHS=/absolute/path/to/your-plugin
```

Then regenerate and restart:

```bash
./scripts/generate-compose.sh
./scripts/stop.sh 8.3 6.8 && ./scripts/start.sh 8.3 6.8
./scripts/activate-mounted-plugins.sh 8.3 6.8
```

Edits to your plugin files now propagate to the container live. Full
details: [bind-mount.md](bind-mount.md).

## Skip WooCommerce for a faster boot

Only testing against plain WordPress? Set this in `.env` before `init.sh`:

```bash
SEED_WOOCOMMERCE=false
```

`init.sh` becomes noticeably faster and produces a WC-free environment.
Default is `true` so nobody with an existing setup is surprised.

## Add CI with one YAML block

In your plugin's GitHub workflow:

```yaml
- uses: actions/checkout@v4
- uses: iserter/wp-test-env@v1
  with:
    php: "8.3"
    wp: "6.8"
    plugin: .
    run: ./vendor/bin/phpunit
```

Full matrix examples: [ci.md](ci.md).

## Write Playwright E2E tests

```bash
npm i -D @iserter/wp-test-env @playwright/test
npx playwright install chromium
```

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';
import { getWpProjects } from '@iserter/wp-test-env/playwright';

export default defineConfig({
    globalSetup: require.resolve('@iserter/wp-test-env/playwright/setup'),
    projects: getWpProjects(),
});
```

```ts
// tests/my-plugin.spec.ts
import { test, expect } from '@iserter/wp-test-env/playwright';

test('settings page loads', async ({ adminPage }) => {
    await adminPage.goto('/wp-admin/admin.php?page=my-plugin');
    await expect(adminPage.getByText('Settings')).toBeVisible();
});
```

See [playwright-fixture.md](playwright-fixture.md) for the full API and a
runnable example under [`examples/fixture-consumer/`](../../examples/fixture-consumer/).

## Tear it down

```bash
# Stop one combo, keep data (restart later, state persists)
./scripts/stop.sh 8.3 6.8

# Stop everything
./scripts/stop.sh

# Nuke one combo's volume + container (asks for confirmation)
./scripts/reset.sh 8.3 6.8

# Nuke the entire stack
./scripts/reset.sh
```

## What next?

- **Make the daily workflow ergonomic:** commit a
  [`wp-test-env.yml`](config-file.md) so `init.sh` / `start.sh` take no
  arguments.
- **Automate init steps:** drop a
  [`hooks/post-init.sh`](hooks.md) script for custom seeding, plugin
  installation, or option tuning.
- **Understand the architecture:** [overview.md](overview.md).
- **Script reference:** [helper-scripts.md](helper-scripts.md).

## Troubleshooting

**"Port already allocated"** — Something on your host is holding the port.
`lsof -i :<port>` to find the culprit, or pick a different PHP × WP combo.

**"Image not found" at build time** — Not every PHP × WP combination has
an official Docker image. The 33 combos in the matrix are all valid; if
you added a new one to `scripts/config.sh`, verify it exists on
[Docker Hub](https://hub.docker.com/_/wordpress/tags).

**Database connection errors on first run** — The DB takes a few seconds
to warm up. `init.sh` waits for it automatically; if you ran
`docker compose up` directly, give it 10 seconds and retry.

**"yq: command not found"** — Only required if you have a
`wp-test-env.yml` in your repo. Install via `brew install yq` or
`apt install yq`, or delete the file to use env vars only.

**Edits to bind-mounted plugin files not reflecting** — Most commonly
OPcache. Flush it: `./scripts/wp.sh 8.3 6.8 eval 'opcache_reset();'`. The
default image ships with a low `opcache.revalidate_freq` so this is
rare — see [bind-mount.md](bind-mount.md) for more.
