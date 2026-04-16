# Using this template

You just created a repo from the `wordpress-test-env` GitHub template. This
guide gets you from zero to a live plugin-dev loop in under two minutes.

## 1. Drop your plugin in `./plugin/`

The template's starter config (`wp-test-env.yml.example`) is pre-wired to
bind-mount a `./plugin/` directory. Create it and put your plugin source
there:

```bash
# Symlink your existing plugin checkout (preferred for live editing)
ln -s /path/to/your-plugin plugin

# …or copy files in
mkdir -p plugin && cp -R /path/to/your-plugin/* plugin/
```

Your plugin will appear as `/var/www/html/wp-content/plugins/plugin` inside
every WP container.

## 2. Activate the starter config + pick a matrix

```bash
cp wp-test-env.yml.example wp-test-env.yml
```

Edit `wp-test-env.yml` to declare which PHP × WP combinations you care
about. The starter is a sensible "boundaries only" set:

```yaml
plugins: [ ./plugin ]
matrix:
  - { php: "8.1", wp: "6.9" }
  - { php: "8.5", wp: "7.0" }
seed:
  woocommerce: false   # set true if your plugin integrates with WC
```

## 3. Boot it

```bash
./scripts/init.sh
./scripts/activate-mounted-plugins.sh
```

Open `http://localhost:<port>/wp-admin` (see the printed status table for
ports). Login is `admin` / `admin`.

## 4. Iterate

Edits under `./plugin/` are reflected in every container instantly — no
rebuild, no restart. Just refresh the browser.

## 5. Upgrade later

The template is a one-shot fork, not a subscription. To pull in upstream
improvements, add the upstream repo as a remote and merge selectively:

```bash
git remote add upstream https://github.com/iSerter/wordpress-test-env.git
git fetch upstream
git merge upstream/main     # review conflicts; typically only in scripts/
```

## Next steps

- [README.md](README.md) — full command reference
- [docs/dev-guide/](docs/dev-guide/) — in-depth guides on bind-mount, hooks,
  config file, CI usage
- [`wp-test-env.schema.json`](wp-test-env.schema.json) — `wp-test-env.yml`
  schema for IDE validation
