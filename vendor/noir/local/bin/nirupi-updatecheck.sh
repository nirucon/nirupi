#!/usr/bin/env bash
# At most once a day, check for available updates (system packages + the
# ~/Git repos) and pop a notification. English; respects NIRUPI_NO_NOTIFY=1.
# Runs from the session (works on Arch, Debian and Void — no systemd timers).
#   nirupi-updatecheck.sh [--force]
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi"
mkdir -p "$cache" 2>/dev/null || true
stamp="$cache/updatecheck.stamp"
today="$(date +%F 2>/dev/null || printf unknown)"

if [[ "${1:-}" != --force && -r $stamp ]] && [[ "$(cat "$stamp" 2>/dev/null)" == "$today" ]]; then
  exit 0
fi

updates_bin="$(command -v nirupi-updates 2>/dev/null || true)"

# System packages (reuse the read-only counter).
pkgs=0
if [[ -n "$updates_bin" ]]; then
  pkgs="$("$updates_bin" 2>/dev/null | tr -dc '0-9' | head -c 6 || true)"
  [[ ${pkgs:-0} =~ ^[0-9]+$ ]] || pkgs=0
fi

# Git checkouts under ~/Git that are behind their upstream. The same helper
# feeds the status bar, so its cache is refreshed here once a day.
repos=0; names=()
if [[ -n "$updates_bin" ]]; then
  repos="$("$updates_bin" --refresh-git --force --wait 2>/dev/null | tr -dc '0-9' | head -c 6 || true)"
  [[ ${repos:-0} =~ ^[0-9]+$ ]] || repos=0
  mapfile -t names < <("$updates_bin" --git-names 2>/dev/null || true)
fi

printf '%s\n' "$today" > "$stamp" 2>/dev/null || true
total=$((pkgs + repos))
(( total > 0 )) || exit 0

msg="System packages: $pkgs"
(( repos > 0 )) && msg="$msg, repos behind: $repos (${names[*]})"
body="$msg
Run: nirupi repos pull   ·   sudo nirupi updates"
if [[ ${NIRUPI_NO_NOTIFY:-0} != 1 ]] && command -v notify-send >/dev/null 2>&1; then
  notify-send -a NIRUPI -u normal "Updates available" "$body"
else
  printf 'Updates available — %s\n' "$msg"
fi
