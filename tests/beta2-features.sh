#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
unset XDG_CONFIG_HOME
export HOME="$tmp/home" XDG_CACHE_HOME="$tmp/home/.cache"
mkdir -p "$XDG_CACHE_HOME/dwm-status" "$HOME/.local/bin" "$HOME/.local/lib/nirupi/0.2.0-beta.2/test/bin"
for f in updates.count updates.stamp updates.db-stamp; do echo 227 > "$XDG_CACHE_HOME/dwm-status/$f"; done
"$ROOT/runtime/nirupi-updates" --refresh >/dev/null
for f in updates.count updates.stamp updates.db-stamp; do [[ ! -e "$XDG_CACHE_HOME/dwm-status/$f" ]]; done
ln -s /tmp/foreign "$XDG_CACHE_HOME/dwm-status/updates.count"
if "$ROOT/runtime/nirupi-updates" --refresh >/dev/null 2>&1; then echo 'FAIL: symlink accepted'; exit 1; fi
[[ -L "$XDG_CACHE_HOME/dwm-status/updates.count" ]]
ln -s "$HOME/.local/lib/nirupi/0.2.0-beta.2/test/bin/dwm" "$HOME/.local/bin/dwm"
[[ $("$ROOT/runtime/nirupi" version) == 0.2.0-beta.2 ]]
[[ $("$ROOT/runtime/nirupi" config) == "$HOME/.config/nirupi/status.conf" ]]
bash -n "$ROOT/vendor/noir/local/bin/dwm-status.sh" "$ROOT/runtime/nirupi-updates" "$ROOT/runtime/nirupi"
grep -Fq 'UPDATES_DB_STAMP' "$ROOT/vendor/noir/local/bin/dwm-status.sh"
echo 'PASS: beta.2 cache refresh, symlink guard, CLI and status config'
