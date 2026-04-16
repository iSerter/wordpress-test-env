# Changelog

## [0.1.3](https://github.com/iSerter/wordpress-test-env/compare/wp-test-env-v0.1.2...wp-test-env-v0.1.3) (2026-04-16)


### Bug Fixes

* **ci:** publish npm package from release-please workflow ([bf4dd06](https://github.com/iSerter/wordpress-test-env/commit/bf4dd06409b4d91d76cd4bfc37e4633c033bf41e))
* **package:** drop ./ prefix from bin path ([fe8736a](https://github.com/iSerter/wordpress-test-env/commit/fe8736aa8a57ac3f5d03d2401984dc708a675b38))

## [0.1.2](https://github.com/iSerter/wordpress-test-env/compare/wp-test-env-v0.1.1...wp-test-env-v0.1.2) (2026-04-16)


### Features

* **action:** add reusable composite GitHub Action for matrix CI ([98a3933](https://github.com/iSerter/wordpress-test-env/commit/98a39337e04f6ec8a0eac8cc37347db885027fd0))
* Add initial configuration files for WordPress multi-version testing environment ([79ea5b2](https://github.com/iSerter/wordpress-test-env/commit/79ea5b26bf082eb70d83ca320929b16e65113759))
* Enhance Docker setup with cron support for WordPress ([7bcb57c](https://github.com/iSerter/wordpress-test-env/commit/7bcb57c3a0ef0acdcaa478b494202edea42643ac))
* Enhance WP-Cron setup in Dockerfile ([c309381](https://github.com/iSerter/wordpress-test-env/commit/c3093819024c029151582eb0d27f0c74f6c7b6f2))
* Ensure uploads directory is created and writable in Docker entrypoint ([7e6907e](https://github.com/iSerter/wordpress-test-env/commit/7e6907ed3f3f7a3c5fb23e878fcf84c579835d1c))
* Introduce apache2-custom-foreground script for wp-content permissions ([619af5a](https://github.com/iSerter/wordpress-test-env/commit/619af5a5457efcb0f1fd27d9f6dc10fa63d23fef))
* Introduce Playwright-based E2E testing and helper scripts for WordPress ([0d302d5](https://github.com/iSerter/wordpress-test-env/commit/0d302d5f3c8b64cbc2092c9a773e8c1f2501e6d2))
* **package:** publish as @iserter/wp-test-env npm package with CLI wrapper ([3140f1d](https://github.com/iSerter/wordpress-test-env/commit/3140f1d9ca2dc34bc83c3f3d2da0bc35197fdfc8))
* **playwright:** export wpFixture and getWpProjects for consumer E2E tests ([b38f82c](https://github.com/iSerter/wordpress-test-env/commit/b38f82c3b279a599857533d696469c9f75a7ec7d))
* **scripts:** gate WooCommerce seeding and add post-init hook ([384ab30](https://github.com/iSerter/wordpress-test-env/commit/384ab3072d2889e7c7d3544ef6d0538de930fbcb))
* **scripts:** support PLUGIN_PATHS for bind-mounted plugin development ([a8674db](https://github.com/iSerter/wordpress-test-env/commit/a8674dbd17fd4f1138e4fe3d0c339b7769a5f072))
* **scripts:** support wp-test-env.yml project config file ([75ba09c](https://github.com/iSerter/wordpress-test-env/commit/75ba09c4d718f5537bee52beb4d126766b3882eb))
* Update Dockerfile to increase PHP upload limits ([efca290](https://github.com/iSerter/wordpress-test-env/commit/efca290455cbd9f69029176cfbc077347e93d27a))


### Bug Fixes

* **package:** update description to include theme developers ([a16c0b9](https://github.com/iSerter/wordpress-test-env/commit/a16c0b9d98dba0dd6a47d9f4c66f821491d0a1ed))
* Update PHP and WordPress versions in setup scripts ([d932571](https://github.com/iSerter/wordpress-test-env/commit/d932571fe74528685a175ae9a5e9b238d450550f))
* Update README and scripts for database instance count and logging improvements ([4314da9](https://github.com/iSerter/wordpress-test-env/commit/4314da9eb8bc30939c537527451d25d58eb3aca3))


### Miscellaneous

* Add MIT License to the project ([2d99b82](https://github.com/iSerter/wordpress-test-env/commit/2d99b82d43ffc715be675986a1b882ff50babb6c))
* Add release-please configuration and workflow ([83e4221](https://github.com/iSerter/wordpress-test-env/commit/83e4221a9ea5fa87a3f97143b6934aad959b8e7d))
* **main:** release 0.1.1 ([a586590](https://github.com/iSerter/wordpress-test-env/commit/a5865906cbcbaaf031625f1e141c1442b54f49c4))
* **main:** release 0.1.1 ([886ee17](https://github.com/iSerter/wordpress-test-env/commit/886ee176618803f2e5480932bc2bec480a63f2ec))
* **tasks:** remove obsolete task files and add .gitkeep ([8b590c6](https://github.com/iSerter/wordpress-test-env/commit/8b590c6af984f7400a277f98b947dc95b2e27185))


### Documentation

* add dev-guide overview, quickstart, npm-publish guide, and DX plans ([8fafe00](https://github.com/iSerter/wordpress-test-env/commit/8fafe00da0644e74c88c6bf267db7cbd3c52446d))
* **readme:** document v0.2.0 features and positioning vs @wordpress/env ([91910ef](https://github.com/iSerter/wordpress-test-env/commit/91910ef54e7eb54f58e7f1ea24aae0f189b42c9d))

## [0.1.1](https://github.com/iSerter/wordpress-test-env/compare/v0.1.0...v0.1.1) (2026-04-12)


### Features

* Add initial configuration files for WordPress multi-version testing environment ([79ea5b2](https://github.com/iSerter/wordpress-test-env/commit/79ea5b26bf082eb70d83ca320929b16e65113759))
* Enhance Docker setup with cron support for WordPress ([7bcb57c](https://github.com/iSerter/wordpress-test-env/commit/7bcb57c3a0ef0acdcaa478b494202edea42643ac))
* Enhance WP-Cron setup in Dockerfile ([c309381](https://github.com/iSerter/wordpress-test-env/commit/c3093819024c029151582eb0d27f0c74f6c7b6f2))
* Ensure uploads directory is created and writable in Docker entrypoint ([7e6907e](https://github.com/iSerter/wordpress-test-env/commit/7e6907ed3f3f7a3c5fb23e878fcf84c579835d1c))
* Introduce apache2-custom-foreground script for wp-content permissions ([619af5a](https://github.com/iSerter/wordpress-test-env/commit/619af5a5457efcb0f1fd27d9f6dc10fa63d23fef))
* Introduce Playwright-based E2E testing and helper scripts for WordPress ([0d302d5](https://github.com/iSerter/wordpress-test-env/commit/0d302d5f3c8b64cbc2092c9a773e8c1f2501e6d2))
* Update Dockerfile to increase PHP upload limits ([efca290](https://github.com/iSerter/wordpress-test-env/commit/efca290455cbd9f69029176cfbc077347e93d27a))


### Bug Fixes

* Update PHP and WordPress versions in setup scripts ([d932571](https://github.com/iSerter/wordpress-test-env/commit/d932571fe74528685a175ae9a5e9b238d450550f))
* Update README and scripts for database instance count and logging improvements ([4314da9](https://github.com/iSerter/wordpress-test-env/commit/4314da9eb8bc30939c537527451d25d58eb3aca3))


### Miscellaneous

* Add MIT License to the project ([2d99b82](https://github.com/iSerter/wordpress-test-env/commit/2d99b82d43ffc715be675986a1b882ff50babb6c))
* Add release-please configuration and workflow ([83e4221](https://github.com/iSerter/wordpress-test-env/commit/83e4221a9ea5fa87a3f97143b6934aad959b8e7d))
