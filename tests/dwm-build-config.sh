#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
# Test the real build-config selector, extracted without running install_desktop.
eval "$(sed -n '/^select_dwm_build_config() {/,/^}/p' "$ROOT/lib/install.sh")"
eval "$(sed -n '/^dwm_config_version() {/,/^}/p' "$ROOT/lib/install.sh")"
eval "$(sed -n '/^dwm_config_current() {/,/^}/p' "$ROOT/lib/install.sh")"
log(){ :; }; die(){ printf '%s\n' "$*" >&2; exit 1; }
BUNDLED="$TMP/bundled"; CUSTOM="$TMP/user"; STAGED="$TMP/staged"
printf 'bundled\n' > "$BUNDLED"
select_dwm_build_config "$BUNDLED" "$CUSTOM" "$STAGED"
[[ $(cat "$STAGED") == bundled ]]
printf 'custom\n' > "$CUSTOM"
select_dwm_build_config "$BUNDLED" "$CUSTOM" "$STAGED"
[[ $(cat "$STAGED") == custom && $(cat "$CUSTOM") == custom ]]
rm "$CUSTOM"; ln -s "$BUNDLED" "$CUSTOM"
if (select_dwm_build_config "$BUNDLED" "$CUSTOM" "$STAGED") >/dev/null 2>&1; then echo 'FAIL: symlink config accepted' >&2; exit 1; fi
rm "$CUSTOM"; mkdir "$CUSTOM"
if (select_dwm_build_config "$BUNDLED" "$CUSTOM" "$STAGED") >/dev/null 2>&1; then echo 'FAIL: directory config accepted' >&2; exit 1; fi
printf 'PASS: DWM build uses user config, falls back to bundled, rejects unsafe paths\n'

# Schema version gating: only a config whose version >= the bundled one may be
# compiled (dwm.c rejects older schemas at compile time).
BCFG="$TMP/bundled.h"; UCFG="$TMP/user.h"
printf '#define NIRUPI_CONFIG_VERSION 3\n' > "$BCFG"
printf '#define NIRUPI_CONFIG_VERSION 2\n' > "$UCFG"
[[ $(dwm_config_version "$UCFG") == 2 ]] || { echo 'FAIL version parse' >&2; exit 1; }
if dwm_config_current "$UCFG" "$BCFG"; then echo 'FAIL: older schema accepted' >&2; exit 1; fi
printf '#define NIRUPI_CONFIG_VERSION 3\n' > "$UCFG"
dwm_config_current "$UCFG" "$BCFG" || { echo 'FAIL: current schema rejected' >&2; exit 1; }
printf '/* no marker */\n' > "$UCFG"
if dwm_config_current "$UCFG" "$BCFG"; then echo 'FAIL: unmarked config accepted' >&2; exit 1; fi
[[ $(dwm_config_version "$UCFG") == 0 ]] || { echo 'FAIL unmarked version' >&2; exit 1; }
printf 'PASS: DWM schema version gating rejects stale configs\n'
