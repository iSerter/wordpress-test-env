/** WordPress admin selectors */
export const WP = {
  login: {
    username: '#user_login',
    password: '#user_pass',
    submit: '#wp-submit',
    error: '#login_error',
  },
  dashboard: {
    heading: '#dashboard-widgets-wrap, .wrap h1',
    adminBar: '#wpadminbar',
    notices: '.notice-error, .error',
    phpError: '.php-error, [class*="fatal"]',
  },
  admin: {
    menu: '#adminmenu',
    contentWrap: '.wrap',
  },
};

/** WooCommerce selectors */
export const WC = {
  shop: {
    products: '.products .product, ul.products li.product',
    productLink: '.woocommerce-loop-product__link, .product a.woocommerce-LoopProduct-link',
    addToCart: '.add_to_cart_button, button[name="add-to-cart"]',
  },
  cart: {
    table: '.woocommerce-cart-form, .shop_table.cart',
    item: '.cart_item, .woocommerce-cart-form__cart-item',
    checkout: '.checkout-button, a.wc-proceed-to-checkout',
  },
  checkout: {
    firstName: '#billing_first_name',
    lastName: '#billing_last_name',
    address: '#billing_address_1',
    city: '#billing_city',
    postcode: '#billing_postcode',
    phone: '#billing_phone',
    email: '#billing_email',
    placeOrder: '#place_order',
    orderReceived: '.woocommerce-order-received, .woocommerce-thankyou-order-received',
  },
  admin: {
    ordersPage: '.wp-list-table.orders, #woocommerce-order-items, .woocommerce-orders-table',
  },
};
