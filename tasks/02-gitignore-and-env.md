# Task 02: Git Ignore & Environment Configuration

**Phase:** 1 - Core Infrastructure
**Status:** Pending
**Depends on:** Task 01

## Objective

Create `.gitignore` and `.env.example` so the repo is clean and new users can onboard quickly.

## Details

### `.gitignore`

Should ignore:
- `.env` (contains credentials)
- Docker volumes / data directories (if any are bind-mounted)
- OS files (`.DS_Store`, `Thumbs.db`)
- IDE files (`.idea/`, `.vscode/`, `*.code-workspace`)
- `wp-data/` or any local WordPress file mounts
- `db-data/` or any local DB mounts
- `*.log`

### `.env.example`

Template with all variables used in `docker-compose.yml` and scripts:

```env
# Database
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress

# WordPress Admin
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin
WP_ADMIN_EMAIL=admin@example.com

# Site
WP_SITE_TITLE=WP Test
```

### Acceptance Criteria

- [ ] `.gitignore` prevents committing sensitive/generated files
- [ ] `.env.example` documents all required environment variables
- [ ] A new user can `cp .env.example .env` and get running
