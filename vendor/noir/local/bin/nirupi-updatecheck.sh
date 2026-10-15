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

# System packages (reuse the read-only counter).
pkgs=0
if command -v nirupi-updates >/dev/null 2>&1; then
  pkgs="$(nirupi-updates 2>/dev/null | tr -dc '0-9' | head -c 6 || true)"
  [[ ${pkgs:-0} =~ ^[0-9]+$ ]] || pkgs=0
fi

# Git repos under ~/Git that are behind their upstream.
repos=0; names=()
for d in "$HOME"/Git/*; do
  [[ -d $d/.git ]] || continue
  git -C "$d" fetch -q --prune 2>/dev/null || true
  n="$(git -C "$d" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || printf 0)"
  [[ ${n:-0} =~ ^[0-9]+$ ]] || n=0
  if (( n > 0 )); then repos=$((repos + 1)); names+=("$(basename "$d")"); fi
done

printf '%s\n' "$today" > "$stamp" 2>/dev/null || true
total=$((pkgs + repos))
(( total > 0 )) || exit 0

msg="System packages: $pkgs"
(( repos > 0 )) && msg="$msg, repos behind: $repos (${names[*]})"
body="$msg
Run: nirupi update   ·   sudo nirupi updates"
if [[ ${NIRUPI_NO_NOTIFY:-0} != 1 ]] && command -v notify-send >/dev/null 2>&1; then
  notify-send -a NIRUPI -u normal "Updates available" "$body"
else
  printf 'Updates available — %s\n' "$msg"
fi
