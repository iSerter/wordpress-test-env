<?php
/**
 * Plugin Name: Example Plugin
 * Description: Fixture plugin used by the wp-test-env test suite to verify
 *              bind-mounted plugin live-reload and CI integration.
 * Version:     0.1.0
 * Author:      wp-test-env
 */

defined( 'ABSPATH' ) || exit;

// Sentinel constant so tests can assert the plugin loaded from a bind mount.
define( 'WP_TEST_ENV_EXAMPLE_PLUGIN_VERSION', '0.1.0' );
