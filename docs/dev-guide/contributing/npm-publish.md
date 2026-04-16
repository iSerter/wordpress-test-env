# Configuring `npm publish`

This doc covers the one-time setup required for `@iserter/wp-test-env` to
auto-publish to the npm registry on every GitHub release.

The automation itself is implemented in:

- [`package.json`](../../../package.json) — `"name": "@iserter/wp-test-env"`,
  `"publishConfig": { "access": "public" }`, `prepublishOnly: npm run build`,
  a `files` array that controls what ships in the tarball.
- [`.github/workflows/npm-publish.yml`](../../../.github/workflows/npm-publish.yml)
  — the workflow that runs `npm publish --provenance --access public` when
  a GitHub release is published.
- [`.github/workflows/release-please.yml`](../../../.github/workflows/release-please.yml)
  — release-please opens release PRs and cuts GitHub releases when they merge.

You only need to do the setup below once. After that, publishing is fully
automatic: merge the release-please PR → GitHub release is created → npm
publish workflow fires → package appears on npmjs.com.

---

## 1. Set up the npm scope `@iserter`

The package is published under the scoped name `@iserter/wp-test-env`,
which requires the `@iserter` scope to be owned by your npm account or an
npm organization.

### Option A — User scope (simplest)

Scoped packages under `@<your-npm-username>` work out of the box once
you're logged in locally:

```bash
npm login
# If your npm username is not "iserter", either:
#   (a) change it on npmjs.com, OR
#   (b) edit package.json's "name" to "@<your-username>/wp-test-env"
#       and update every @iserter/wp-test-env reference in the repo.
```

Verify:

```bash
npm whoami          # → iserter (or whatever your username is)
```

### Option B — Organization scope (shared maintenance)

If you want multiple maintainers or a dedicated org:

1. Go to https://www.npmjs.com/org/create and create the `iserter` org.
2. Add co-maintainers under **Members**.
3. Ensure the org is on the free plan if the package should remain public
   (the free plan publishes **public** scoped packages; private scoped
   packages need a paid plan).

Once the org exists, the npm CLI treats it the same as a user scope for
publishing purposes.

---

## 2. Generate an npm automation token

A GitHub Actions workflow can't log in interactively, so it needs a
long-lived token. Use an **automation** token — it has `2FA` exempted
(required for CI) and is scoped to publishing, not full account control.

1. Go to https://www.npmjs.com/settings/<your-username>/tokens and click
   **Generate New Token** → **Classic Token**.
2. Pick **Automation** as the token type.
3. Copy the token once it's displayed. It starts with `npm_…`. You will
   **not** see it again.

> **Why a classic automation token and not the newer granular token?**
> As of 2026-Q1, granular tokens don't yet support OIDC-based provenance
> in all npm flows. Revisit this when npm fully transitions to granular
> tokens. See https://docs.npmjs.com/about-access-tokens.

---

## 3. Add the token as a GitHub repo secret

1. On GitHub, navigate to the repo's **Settings → Secrets and variables →
   Actions**.
2. Click **New repository secret**.
3. Name: `NPM_TOKEN` (must match the name referenced in
   `.github/workflows/npm-publish.yml`).
4. Value: the `npm_…` token from step 2.
5. Save.

---

## 4. (Recommended) Enable npm provenance

Provenance cryptographically links a published package version to the
GitHub workflow run that produced it, so consumers can verify the tarball
came from this repo. Our workflow already passes `--provenance` and sets
`id-token: write` permission. Two requirements for it to actually work:

- **The repository must be public on GitHub.** (Private repos can't emit
  the required OIDC tokens for npm verification.)
- **The npm package must allow provenance.** This is on by default for
  new public packages. Nothing to configure.

Verify after first publish:

```bash
npm view @iserter/wp-test-env
```

A successful provenance shows a `Provenance` block with "Source Commit"
and "Build File" links pointing back to this repo.

---

## 5. Verify end-to-end before trusting automation

Before relying on the release-please → npm flow, do a manual dry run to
catch auth problems without burning a version number:

```bash
# From a clean checkout
npm ci
npm run build
npm pack --dry-run    # confirm the file list looks right

# Actual auth check (does not publish — requires manual local login)
npm login
npm publish --dry-run --provenance --access public
```

If this shows `+ @iserter/wp-test-env@0.1.1` (or whatever's in
package.json) and no errors, real publishes will work.

---

## Release flow in practice

Once the setup above is done, publishing is hands-off:

1. **Write conventional commits** on `main`:
   ```
   feat: add PLUGIN_PATHS for bind-mounted plugin development
   fix(scripts): handle spaces in PLUGIN_PATHS entries
   docs: add Playwright fixture guide
   ```
2. **release-please opens a release PR** within a few minutes of each push
   to `main`. The PR's body shows the proposed version bump (based on
   `feat:` = minor, `fix:` = patch, `BREAKING CHANGE:` = major) and a
   draft CHANGELOG.
3. **Merge the release PR** when you're ready to cut a release. Merging it
   triggers release-please to:
   - Commit the CHANGELOG update and bumped `package.json` version.
   - Create a git tag `vX.Y.Z`.
   - Publish a GitHub Release with the CHANGELOG notes.
4. **The npm-publish workflow fires** on the `release: published` event.
   It re-checks that `package.json` version matches the tag, runs
   `prepublishOnly` (which runs `npm run build` to emit the Playwright
   fixture `dist/`), and publishes.

Confirm on https://www.npmjs.com/package/@iserter/wp-test-env that the
new version is live.

## GitHub Action tag (`v1`, `v2`, …)

Separately from npm, `action.yml` means this repo is also a GitHub Action.
Users pin with `uses: iserter/wp-test-env@v1`, which is a floating major
tag that should always point at the latest `v1.x.y` release.

After each release that ships action-compatible changes:

```bash
# Assuming the new tag is v0.2.0 and v1 floats over 0.x
git tag -f v1 v0.2.0
git push origin v1 --force
```

This is the **only** place `--force` is used in the project; the scope is
limited to a ref pattern not used by any PR workflow.

## Troubleshooting

**401 Unauthorized during publish** — `NPM_TOKEN` secret is missing,
malformed, or expired. Re-generate and re-add.

**403 Forbidden: "You do not have permission to publish ..."** — The
`@iserter` scope is owned by someone else, or your npm account isn't a
member. Check https://www.npmjs.com/~<your-username>.

**"package.json version does not match tag"** — The guard step in
npm-publish.yml caught a mismatch. This usually means someone edited
`package.json` version by hand instead of going through release-please.
Fix `package.json`, retrigger the workflow manually via the Actions tab.

**Provenance block missing on published version** — The repo is private,
the workflow doesn't have `id-token: write` permission, or npm is not yet
aware of the repo as a provenance source. Check the workflow run logs for
an OIDC-related warning.

**npm publish succeeds but `npm i @iserter/wp-test-env` installs an old
version** — npm CDN cache. Usually clears within 5 minutes; force refresh
with `npm i @iserter/wp-test-env@X.Y.Z` by exact version.

## Rollback / unpublish

npm allows unpublish **only within 72 hours of publish** and only under
specific conditions. If you need to pull a bad release:

```bash
# Within 72 hours — wipes the version
npm unpublish @iserter/wp-test-env@X.Y.Z

# After 72 hours — deprecate instead (marks it installed-with-warning)
npm deprecate @iserter/wp-test-env@X.Y.Z "Use X.Y.Z+1 instead — <reason>"
```

For anything beyond 72 hours, the right fix is usually to ship a patch
version (`X.Y.Z+1`) that corrects the issue. Unpublishing published
tarballs is disruptive to consumers and npm discourages it.
