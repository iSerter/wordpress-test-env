#!/usr/bin/env bash
# Loads settings from wp-test-env.yml (or .wp-test-env.yml).
# Sourced by scripts/config.sh; must run AFTER .env is loaded and BEFORE
# parse_plugin_paths.
#
# Search order (first match wins):
#   1. $WPTE_CALLER_CWD/wp-test-env.yml        (caller's dir — set by npm shim)
#   2. $WPTE_CALLER_CWD/.wp-test-env.yml
#   3. $PROJECT_DIR/wp-test-env.yml            (repo root — classic usage)
#   4. $PROJECT_DIR/.wp-test-env.yml
#
# Relative paths within the yml resolve against the YML FILE's directory,
# not against PROJECT_DIR — so a yml in the caller's plugin repo refers
# to the caller's files, not the installed package.
#
# Precedence for individual values: existing env var (non-empty) > yml.
# Silent no-op when no config file is present. When present but `yq` is
# not installed, fails fast with install instructions.

_WPTE_CONFIG=""
_wpte_candidates=()
[[ -n "${WPTE_CALLER_CWD:-}" ]] && _wpte_candidates+=(
    "$WPTE_CALLER_CWD/wp-test-env.yml"
    "$WPTE_CALLER_CWD/.wp-test-env.yml"
)
_wpte_candidates+=(
    "$PROJECT_DIR/wp-test-env.yml"
    "$PROJECT_DIR/.wp-test-env.yml"
)
for _candidate in "${_wpte_candidates[@]}"; do
    if [[ -f "$_candidate" ]]; then
        _WPTE_CONFIG="$_candidate"
        break
    fi
done
unset _candidate _wpte_candidates

if [[ -z "$_WPTE_CONFIG" ]]; then
    return 0 2>/dev/null || true
fi

if ! command -v yq >/dev/null 2>&1; then
    log_error "$(basename "$_WPTE_CONFIG") found but 'yq' is not installed."
    log_error "  Install: brew install yq  |  apt install yq"
    log_error "  See:     https://github.com/mikefarah/yq"
    exit 1
fi

_WPTE_CONFIG_DIR=$(dirname "$_WPTE_CONFIG")

# Resolve a path against the config file's directory (absolute paths pass through).
_wpte_resolve() {
    case "$1" in
        /*) printf '%s' "$1" ;;
        *)  printf '%s/%s' "$_WPTE_CONFIG_DIR" "$1" ;;
    esac
}

# plugins → PLUGIN_PATHS (resolved to absolute paths)
if [[ -z "${PLUGIN_PATHS:-}" ]]; then
    _yml_plugins_raw=$(yq '.plugins // [] | join(",")' "$_WPTE_CONFIG" 2>/dev/null || echo "")
    if [[ -n "$_yml_plugins_raw" ]] && [[ "$_yml_plugins_raw" != "null" ]]; then
        IFS=',' read -ra _parts <<< "$_yml_plugins_raw"
        _resolved=()
        for _p in "${_parts[@]}"; do
            _p="${_p#"${_p%%[![:space:]]*}"}"
            _p="${_p%"${_p##*[![:space:]]}"}"
            [[ -z "$_p" ]] && continue
            _resolved+=("$(_wpte_resolve "$_p")")
        done
        if [[ ${#_resolved[@]} -gt 0 ]]; then
            _joined=$(IFS=','; echo "${_resolved[*]}")
            export PLUGIN_PATHS="$_joined"
            unset _joined
        fi
        unset _parts _resolved _p
    fi
    unset _yml_plugins_raw
fi

# seed.woocommerce → SEED_WOOCOMMERCE
if [[ -z "${SEED_WOOCOMMERCE:-}" ]]; then
    _yml_seed=$(yq '.seed.woocommerce // "null"' "$_WPTE_CONFIG" 2>/dev/null || echo "null")
    if [[ "$_yml_seed" != "null" ]]; then
        export SEED_WOOCOMMERCE="$_yml_seed"
    fi
    unset _yml_seed
fi

# matrix → MATRIX_CONSTRAINT
_yml_matrix=$(yq '.matrix // [] | map(.php + ":" + .wp) | join(" ")' "$_WPTE_CONFIG" 2>/dev/null || echo "")
if [[ -n "$_yml_matrix" ]] && [[ "$_yml_matrix" != "null" ]]; then
    export MATRIX_CONSTRAINT="$_yml_matrix"
fi
unset _yml_matrix

# hooks.post-init → POST_INIT_HOOK (resolved)
if [[ -z "${POST_INIT_HOOK:-}" ]]; then
    _yml_hook=$(yq '.hooks["post-init"] // ""' "$_WPTE_CONFIG" 2>/dev/null || echo "")
    if [[ -n "$_yml_hook" ]] && [[ "$_yml_hook" != "null" ]]; then
        export POST_INIT_HOOK="$(_wpte_resolve "$_yml_hook")"
    fi
    unset _yml_hook
fi

unset _WPTE_CONFIG _WPTE_CONFIG_DIR
unset -f _wpte_resolve
