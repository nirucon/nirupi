#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
# Test the real build-config selector, extracted without running install_desktop.
eval "$(sed -n '/^select_dwm_build_config() {/,/^}/p' "$ROOT/lib/install.sh")"
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
