# Task 07: End-to-End Testing & Documentation

**Phase:** 1 - Core Infrastructure
**Status:** Pending
**Depends on:** Tasks 01–06

## Objective

Test the full setup end-to-end and update the README with usage instructions.

## Details

### Testing

1. Start from a clean state (no containers, no volumes)
2. Run `./scripts/init.sh`
3. Verify all 10 WordPress instances:
   - Site loads at `http://localhost:80XX`
   - Admin login works at `http://localhost:80XX/wp-admin`
   - WooCommerce is active and shop page shows products
   - Orders and customers exist in WooCommerce admin
4. Test `./scripts/stop.sh` and `./scripts/start.sh` (data persists)
5. Test `./scripts/reset.sh` (clean slate)
6. Test partial operations (single version start/stop)

### README Updates

Update `README.md` with:

- **Overview**: What this repo does
- **Prerequisites**: Docker, Docker Compose, available ports
- **Quick Start**: `git clone → cp .env.example .env → ./scripts/init.sh`
- **Version Table**: All WP versions with their ports and URLs
- **Scripts Reference**: Brief description of each script
- **Credentials**: Default admin user/pass
- **Troubleshooting**: Common issues (port conflicts, Docker memory, slow first build)

### Acceptance Criteria

- [ ] Full init from scratch works without manual intervention
- [ ] README enables a new user to get running without additional help
- [ ] All 10 instances pass the verification checklist above
