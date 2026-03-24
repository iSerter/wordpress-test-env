<?php
/**
 * Seed extra WooCommerce data: customers, orders, and coupons.
 * Run via: wp eval-file /dev/stdin < seed-extra.php
 */

if ( ! class_exists( 'WooCommerce' ) ) {
    WP_CLI::error( 'WooCommerce is not active.' );
}

// ── Customers ──────────────────────────────────────────────────
$customers = [
    [ 'email' => 'john@example.com',  'first' => 'John',  'last' => 'Doe'    ],
    [ 'email' => 'jane@example.com',  'first' => 'Jane',  'last' => 'Smith'  ],
    [ 'email' => 'bob@example.com',   'first' => 'Bob',   'last' => 'Wilson' ],
    [ 'email' => 'alice@example.com', 'first' => 'Alice', 'last' => 'Brown'  ],
    [ 'email' => 'carol@example.com', 'first' => 'Carol', 'last' => 'Davis'  ],
];

$customer_ids = [];
foreach ( $customers as $c ) {
    if ( email_exists( $c['email'] ) ) {
        $customer_ids[] = email_exists( $c['email'] );
        WP_CLI::log( "Customer {$c['email']} already exists, skipping." );
        continue;
    }
    $customer = new WC_Customer();
    $customer->set_email( $c['email'] );
    $customer->set_first_name( $c['first'] );
    $customer->set_last_name( $c['last'] );
    $customer->set_username( strtolower( $c['first'] ) );
    $customer->set_password( 'password' );
    $customer->set_billing_first_name( $c['first'] );
    $customer->set_billing_last_name( $c['last'] );
    $customer->set_billing_email( $c['email'] );
    $customer->set_billing_address_1( '123 Test St' );
    $customer->set_billing_city( 'San Francisco' );
    $customer->set_billing_state( 'CA' );
    $customer->set_billing_postcode( '94103' );
    $customer->set_billing_country( 'US' );
    $customer->save();
    $customer_ids[] = $customer->get_id();
    WP_CLI::log( "Created customer: {$c['first']} {$c['last']}" );
}

// ── Get product IDs for orders ─────────────────────────────────
$product_ids = wc_get_products( [
    'limit'  => 10,
    'return' => 'ids',
    'status' => 'publish',
] );

if ( empty( $product_ids ) ) {
    WP_CLI::warning( 'No products found — skipping order creation.' );
} else {

    // ── Orders ─────────────────────────────────────────────────
    $statuses = [ 'pending', 'processing', 'completed', 'completed', 'processing',
                  'on-hold', 'completed', 'refunded', 'processing', 'completed' ];

    // Only create orders if none exist yet
    $existing_orders = wc_get_orders( [ 'limit' => 1, 'return' => 'ids' ] );
    if ( ! empty( $existing_orders ) ) {
        WP_CLI::log( 'Orders already exist, skipping order creation.' );
    } else {
        foreach ( $statuses as $i => $status ) {
            $order = wc_create_order( [
                'customer_id' => $customer_ids[ $i % count( $customer_ids ) ],
                'status'      => $status,
            ] );

            // Add 1-3 random products
            $num_items = rand( 1, 3 );
            $shuffled  = $product_ids;
            shuffle( $shuffled );
            for ( $j = 0; $j < $num_items && $j < count( $shuffled ); $j++ ) {
                $product = wc_get_product( $shuffled[ $j ] );
                if ( $product ) {
                    $order->add_product( $product, rand( 1, 3 ) );
                }
            }

            $order->calculate_totals();
            $order->save();
            WP_CLI::log( "Created order #{$order->get_id()} — status: {$status}" );
        }
    }
}

// ── Coupons ────────────────────────────────────────────────────
$coupons_data = [
    [ 'code' => 'SAVE10',    'type' => 'percent',    'amount' => '10', 'desc' => '10% off' ],
    [ 'code' => 'FLAT5',     'type' => 'fixed_cart',  'amount' => '5',  'desc' => '$5 off'  ],
    [ 'code' => 'FREESHIP',  'type' => 'percent',    'amount' => '0',  'desc' => 'Free shipping', 'free_shipping' => true ],
];

foreach ( $coupons_data as $cd ) {
    // Check if coupon exists
    $existing = new WC_Coupon( $cd['code'] );
    if ( $existing->get_id() ) {
        WP_CLI::log( "Coupon {$cd['code']} already exists, skipping." );
        continue;
    }

    $coupon = new WC_Coupon();
    $coupon->set_code( $cd['code'] );
    $coupon->set_discount_type( $cd['type'] );
    $coupon->set_amount( $cd['amount'] );
    $coupon->set_description( $cd['desc'] );
    if ( ! empty( $cd['free_shipping'] ) ) {
        $coupon->set_free_shipping( true );
    }
    $coupon->save();
    WP_CLI::log( "Created coupon: {$cd['code']} — {$cd['desc']}" );
}

WP_CLI::success( 'Extra seed data created.' );
