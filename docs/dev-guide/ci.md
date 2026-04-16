# CI — Using the GitHub Action

The `iserter/wp-test-env` repo doubles as a reusable GitHub Action, so you
can run your plugin's test suite against the full PHP × WP matrix without
hand-rolling `docker compose` boilerplate in your workflow.

## Single-version

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: iserter/wp-test-env@v1
        with:
          php: "8.3"
          wp: "6.8"
          plugin: .
          run: ./vendor/bin/phpunit
```

The `run` command executes inside the WP container with working directory
set to your plugin's mount path, so relative paths like `./vendor/bin/phpunit`
or `./tests/` work exactly as they do locally.

## Full matrix

```yaml
jobs:
  compatibility:
    name: PHP ${{ matrix.php }} / WP ${{ matrix.wp }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - { php: "8.1", wp: "6.1" }   # oldest supported
          - { php: "8.1", wp: "6.9" }
          - { php: "8.5", wp: "6.9" }
          - { php: "8.5", wp: "7.0" }   # newest supported (beta)
    steps:
      - uses: actions/checkout@v4
      - uses: iserter/wp-test-env@v1
        with:
          php: ${{ matrix.php }}
          wp: ${{ matrix.wp }}
          plugin: .
          run: ./vendor/bin/phpunit
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `php` | yes | — | PHP version, e.g. `"8.3"` |
| `wp`  | yes | — | WP version, e.g. `"6.8"` |
| `plugin` | no | `"."` | Path to the plugin directory relative to `github.workspace`. Bind-mounted as `/var/www/html/wp-content/plugins/<basename>`. |
| `run` | no | `""` | Command to execute inside the WP container. Leave empty to just boot the env and use the container in later steps. |
| `woocommerce` | no | `"true"` | Install WooCommerce + sample data. Set `"false"` for non-WC plugins. |

## Valid PHP × WP combinations

The Action relies on the official `wordpress:<wp>-php<php>-apache` Docker
image tags. See the [README port table](../../README.md#full-port-table)
for the current combination matrix. Using an invalid combo will fail at
the "Boot instance" step with a clear Docker error.

## Running additional commands against the booted env

Leave `run` empty and the Action just boots the env — it leaves containers
running for subsequent steps in the same job. Use `docker compose exec` or
the bundled `scripts/wp.sh` to interact with the container:

```yaml
- uses: iserter/wp-test-env@v1
  with:
    php: "8.3"
    wp: "6.8"
    plugin: .
- name: Import fixtures
  run: docker compose -f ./docker-compose.yml exec -T wp-83-68 wp --allow-root import fixtures/demo.xml
- name: Run tests
  run: docker compose -f ./docker-compose.yml exec -T wp-83-68 bash -lc "cd /var/www/html/wp-content/plugins/my-plugin && ./vendor/bin/phpunit"
```

## Performance notes

- Each Action invocation builds the WP Docker image from scratch (~30–60s).
  Cache with `actions/cache` keyed on `Dockerfile` hash for repeated runs.
- The `woocommerce: false` flag cuts init time significantly for plugins
  that don't need WC.
- For matrix jobs that share a plugin tree, prefer one job per PHP × WP
  pair over running all inside one job — the default Action design assumes
  one `init.sh` invocation per job.

## Versioning

- `iserter/wp-test-env@v1` — floating major tag, follows every `v0.x` and
  `v1.x` release (breaking changes move to `@v2`).
- `iserter/wp-test-env@v0.2.0` — pin to exact release for reproducibility.
- `iserter/wp-test-env@<sha>` — pin to specific commit (best for security
  audits).
