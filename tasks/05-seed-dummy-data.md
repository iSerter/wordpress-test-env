# Task 05: Seed Dummy Data

**Phase:** 1 - Core Infrastructure
**Status:** Pending
**Depends on:** Task 04

## Objective

Create a script that populates each WordPress + WooCommerce instance with realistic dummy data for testing.

## Details

### Script: `scripts/seed-data.sh`

#### WordPress Content

- **Pages**: Home, About, Contact, Shop, Cart, Checkout, My Account (WooCommerce pages should already exist)
- **Posts**: 3–5 sample blog posts with varied content

#### WooCommerce Data

- **Products** (10–15 products across types):
  - Simple products (5–6): varied prices, some on sale
  - Variable products (2–3): with size/color attributes and variations
  - Virtual/downloadable products (1–2)
  - Include product images (use placeholder URLs or bundled sample images)
  - Assign to categories: Clothing, Electronics, Accessories (or similar)
- **Product Categories**: 3–4 categories with descriptions
- **Customers**: 3–5 test customer accounts
- **Orders**: 5–10 orders in various statuses (pending, processing, completed, refunded)
- **Coupons**: 2–3 test coupons (percentage, fixed amount)

### Approach

Option A — **WooCommerce sample data XML**: WooCommerce ships with `sample-data/sample_products.xml`. Import via `wp import` (requires the WordPress Importer plugin).

Option B — **WP-CLI commands**: Create products, orders, etc. programmatically with `wp wc product create`, `wp wc order create`, etc. More control but more scripting.

**Recommendation**: Use Option A for products (quick, includes images), supplement with Option B for orders, customers, and coupons.

### Acceptance Criteria

- [ ] Each instance has products visible on the shop page
- [ ] Products have categories, prices, and images
- [ ] Test orders exist in WooCommerce → Orders
- [ ] Test customer accounts can log in
- [ ] Script is idempotent or has a `--force` flag to re-seed
