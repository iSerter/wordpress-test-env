# Task 08: Phase 2 — Plugin Development Branch (`with-plugins`)

**Phase:** 2 - Plugin Development
**Status:** Pending
**Depends on:** Phase 1 complete (Tasks 01–07)

## Objective

Create a `with-plugins` branch that extends the base setup with local plugin mounts for development and debugging.

## Details

### Branch: `with-plugins`

Create from `main` after Phase 1 is complete.

### `docker-compose.override.yml`

Docker Compose automatically merges `docker-compose.override.yml` on top of `docker-compose.yml`. This file will:

- **Mount local plugin directories** into each WP container's `/var/www/html/wp-content/plugins/` path
- Use a `plugins/` directory in the repo root as the source

Example structure:
```
plugins/
  my-plugin-a/
  my-plugin-b/
```

The override mounts these into every WP container:
```yaml
services:
  wp-6.1:
    volumes:
      - ./plugins/my-plugin-a:/var/www/html/wp-content/plugins/my-plugin-a
      - ./plugins/my-plugin-b:/var/www/html/wp-content/plugins/my-plugin-b
```

### Helper Scripts

- `scripts/activate-plugins.sh` — activates all mounted plugins on all instances via WP-CLI
- `scripts/deactivate-plugins.sh` — deactivates all mounted plugins

### Plugin Configuration

Create a `plugins.conf` (or similar) that lists plugin directory names to mount, so the override file can be generated dynamically or users can easily add/remove plugins.

### Acceptance Criteria

- [ ] Checking out `with-plugins` and running `docker compose up -d` mounts local plugins
- [ ] Code changes in `plugins/` are reflected immediately in the WP containers (no rebuild needed)
- [ ] Plugins can be activated/deactivated via helper scripts
- [ ] `main` branch remains clean — no plugin-specific configuration
- [ ] Documentation explains how to add new plugins to the setup
