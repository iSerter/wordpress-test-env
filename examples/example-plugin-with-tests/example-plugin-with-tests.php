<?php
/**
 * Plugin Name: Example Plugin With Tests
 * Description: Fixture used by the wp-test-env GitHub Action integration test.
 * Version:     0.1.0
 * Author:      wp-test-env
 */

defined( 'ABSPATH' ) || exit;

define( 'WP_TEST_ENV_ACTION_FIXTURE', '0.1.0' );

add_action( 'init', function () {
    // Expose a canary option so tests can assert the plugin's init ran.
    update_option( 'wp_test_env_action_canary', '1' );
} );
