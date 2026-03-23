# Task 03: WordPress Auto-Setup Script

**Phase:** 1 - Core Infrastructure
**Status:** Pending
**Depends on:** Task 01

## Objective

Create a script that automatically runs the WordPress "5-minute install" via WP-CLI on all instances, so each site is ready to use immediately after `docker compose up`.

## Details

### Script: `scripts/setup-wordpress.sh`

For each WordPress version (6.1–6.9, 7.0):

1. **Wait for the DB** to be healthy (poll `docker compose exec wp-X.Y wp db check` or check container health).
2. **Run `wp core install`** with:
   - `--url=http://localhost:80XX`
   - `--title="WordPress X.Y Test"`
   - `--admin_user` / `--admin_password` / `--admin_email` from `.env`
3. **Configure settings**:
   - Set permalink structure to `/%postname%/`
   - Set timezone to UTC
   - Disable update checks (test env, not production)
   - Enable debug mode (`WP_DEBUG=true`)

### Approach

- Loop through a version list defined at the top of the script (or sourced from a shared config).
- Use `docker compose exec -T wp-X.Y wp ...` to run WP-CLI commands (the `-T` flag disables TTY allocation for non-interactive use).
- Run installations in parallel where possible (using background processes + `wait`).
- Print clear status messages for each version.
- Be idempotent: if WordPress is already installed, skip gracefully.

### Acceptance Criteria

- [ ] Running `./scripts/setup-wordpress.sh` configures all 10 WordPress instances
- [ ] Each site is accessible and shows the WordPress dashboard at `http://localhost:80XX/wp-admin`
- [ ] Admin credentials from `.env` work on all instances
- [ ] Script is idempotent — safe to run multiple times
