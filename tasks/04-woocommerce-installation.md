# Task 04: WooCommerce Installation Script

**Phase:** 1 - Core Infrastructure
**Status:** Pending
**Depends on:** Task 03

## Objective

Create a script that installs and activates WooCommerce on all WordPress instances.

## Details

### Script: `scripts/install-woocommerce.sh`

For each WordPress version:

1. **Install WooCommerce** via WP-CLI:
   ```bash
   wp plugin install woocommerce --activate
   ```
   - Use the latest stable WooCommerce release compatible with each WP version.
   - Note: Very old WP versions (6.1, 6.2) may need a pinned older WooCommerce version if the latest isn't compatible.
2. **Run the WooCommerce setup wizard programmatically** or skip it and configure base settings directly:
   - Store country/currency (e.g., US / USD)
   - Enable basic payment gateway (Cash on Delivery or similar for testing)
   - Set store address (dummy)
3. **Verify** WooCommerce is active: `wp plugin list --status=active --name=woocommerce`

### Compatibility Matrix

Research and document which WooCommerce versions are compatible with each WP version. If needed, pin specific versions:

| WP Version | WooCommerce Version |
|------------|-------------------|
| 6.1        | TBD (research)    |
| 6.2        | TBD               |
| ...        | ...               |
| 7.0        | Latest stable     |

### Acceptance Criteria

- [ ] WooCommerce is installed and activated on all 10 instances
- [ ] WooCommerce admin pages load without errors on each instance
- [ ] Basic store settings are configured (currency, country)
- [ ] Script handles version compatibility gracefully
