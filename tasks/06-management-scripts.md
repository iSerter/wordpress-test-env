# Task 06: Management & Convenience Scripts

**Phase:** 1 - Core Infrastructure
**Status:** Pending
**Depends on:** Task 01

## Objective

Create helper scripts that make it easy to manage the test environment day-to-day.

## Details

### Scripts to Create

#### `scripts/start.sh`
- Runs `docker compose up -d`
- Optionally accepts a version argument to start only one instance: `./scripts/start.sh 6.5`
- Prints a summary table of running instances with their URLs

#### `scripts/stop.sh`
- Runs `docker compose down`
- Optionally accepts a version to stop a single instance
- Does NOT remove volumes by default

#### `scripts/reset.sh`
- Tears down everything including volumes: `docker compose down -v`
- Optionally reset a single version
- Asks for confirmation before proceeding (destructive action)

#### `scripts/status.sh`
- Shows which containers are running, their ports, and health status
- Formatted as a readable table

#### `scripts/init.sh` (main orchestrator)
- The single command to go from zero to fully running:
  1. Copy `.env.example` to `.env` if `.env` doesn't exist
  2. `docker compose up -d --build`
  3. Wait for all containers to be healthy
  4. Run `setup-wordpress.sh`
  5. Run `install-woocommerce.sh`
  6. Run `seed-data.sh`
- Print final summary with all URLs and credentials

### Shared Config

Create `scripts/config.sh` (sourced by all scripts):
- Version list: `VERSIONS=(6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 7.0)`
- Port mapping function
- Common utility functions (logging, color output, waiting for containers)

### Acceptance Criteria

- [ ] `./scripts/init.sh` sets up everything from scratch in one command
- [ ] `./scripts/status.sh` clearly shows the state of all instances
- [ ] Scripts support operating on a single version or all versions
- [ ] All scripts have `--help` usage output
- [ ] Scripts are executable (`chmod +x`)
