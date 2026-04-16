#!/usr/bin/env node
/**
 * wp-test-env — Node shim that forwards subcommands to the bash scripts
 * bundled with this package. Runs scripts from the package install dir so
 * docker-compose and auxiliary files resolve relative to the package, not
 * the caller's CWD.
 *
 * Conveniences:
 *   • Searches for wp-test-env.yml in the caller's CWD first, package second.
 *   • Auto-sets PLUGIN_PATHS=$CWD when the caller looks like a WP plugin
 *     directory (has a .php file with a "Plugin Name:" header) AND no
 *     PLUGIN_PATHS was explicitly provided.
 *
 * Usage: wp-test-env <command> [args...]
 */

'use strict';

const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const PKG_ROOT = path.resolve(__dirname, '..');
const CALLER_CWD = process.cwd();

// subcommand → script filename under scripts/
const COMMANDS = {
    'init':        'init.sh',
    'start':       'start.sh',
    'stop':        'stop.sh',
    'reset':       'reset.sh',
    'status':      'status.sh',
    'logs':        'logs.sh',
    'wp':          'wp.sh',
    'open':        'open.sh',
    'health':      'health-check.sh',
    'plugin':      'install-plugin.sh',
    'activate':    'activate-mounted-plugins.sh',
    'deactivate':  'deactivate-mounted-plugins.sh',
    'test':        'test.sh',
    'export-db':   'export-db.sh',
    'import-db':   'import-db.sh',
    'generate':    'generate-compose.sh',
};

function printUsage() {
    const cmds = Object.keys(COMMANDS).sort().join(', ');
    process.stdout.write(
`wp-test-env — multi-version WordPress test environment

Usage: wp-test-env <command> [args...]

Most commands accept an optional [php_version wp_version] to target a
single instance. Run any command with --help for specifics.

Commands:
  ${cmds}

Options:
  -h, --help       Show this help
  -v, --version    Show package version

Environment:
  PLUGIN_PATHS        Comma-separated plugin dirs to bind-mount
  SEED_WOOCOMMERCE    "false" to skip WC install (default: true)
  wp-test-env.yml     Committed project config (caller's CWD or package root)

Docs: https://github.com/iSerter/wordpress-test-env
`);
}

function printVersion() {
    const pkg = require(path.join(PKG_ROOT, 'package.json'));
    process.stdout.write(`${pkg.version}\n`);
}

function looksLikeWpPlugin(dir) {
    let entries;
    try {
        entries = fs.readdirSync(dir);
    } catch {
        return false;
    }
    for (const f of entries) {
        if (!f.endsWith('.php')) continue;
        try {
            const head = fs.readFileSync(path.join(dir, f), 'utf8').slice(0, 4000);
            if (/^\s*\*?\s*Plugin Name:/mi.test(head)) return true;
        } catch {
            // unreadable — keep looking
        }
    }
    return false;
}

function main(argv) {
    if (argv.length === 0 || argv[0] === '-h' || argv[0] === '--help') {
        printUsage();
        return 0;
    }
    if (argv[0] === '-v' || argv[0] === '--version') {
        printVersion();
        return 0;
    }

    const [cmd, ...rest] = argv;
    const script = COMMANDS[cmd];
    if (!script) {
        process.stderr.write(`wp-test-env: unknown command '${cmd}'\n`);
        process.stderr.write(`Run 'wp-test-env --help' for available commands.\n`);
        return 2;
    }

    const scriptPath = path.join(PKG_ROOT, 'scripts', script);
    if (!fs.existsSync(scriptPath)) {
        process.stderr.write(`wp-test-env: internal error — script missing: ${scriptPath}\n`);
        return 3;
    }

    const env = Object.assign({}, process.env);
    env.WPTE_CALLER_CWD = CALLER_CWD;

    // Auto-default PLUGIN_PATHS to caller's CWD when it looks like a plugin dir.
    // Guarded so `npx` runs inside the package's own repo don't self-mount.
    if (!env.PLUGIN_PATHS && CALLER_CWD !== PKG_ROOT && looksLikeWpPlugin(CALLER_CWD)) {
        env.PLUGIN_PATHS = CALLER_CWD;
    }

    const result = spawnSync('bash', [scriptPath, ...rest], {
        stdio: 'inherit',
        cwd: PKG_ROOT,
        env,
    });

    if (result.error) {
        process.stderr.write(`wp-test-env: failed to exec bash: ${result.error.message}\n`);
        return 4;
    }
    return result.status == null ? 1 : result.status;
}

process.exit(main(process.argv.slice(2)));
