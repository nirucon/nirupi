#!/usr/bin/env bash
# Caffeine: keep the screen awake (no idle lock / DPMS) until toggled off.
# A small bar indicator appears while it is active.
set -Eeuo pipefail

flag="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi/caffeine"
pidf="$flag.pid"
notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }

if [[ -f $flag ]]; then
  rm -f -- "$flag"
  [[ -f $pidf ]] && kill "$(cat "$pidf")" 2>/dev/null || :
  rm -f -- "$pidf"
  command -v xset >/dev/null 2>&1 && xset s default +dpms 2>/dev/null || :
  notify -u low "Caffeine off" "Screen may lock and sleep again"
else
  mkdir -p "$(dirname "$flag")"
  : > "$flag"
  command -v xset >/dev/null 2>&1 && xset s off -dpms 2>/dev/null || :
  # Keep the X idle counter reset so idle lockers (xss-lock/xautolock/xidlehook)
  # never fire while caffeine is on.
  ( while [[ -f $flag ]]; do sleep 45; xset s reset 2>/dev/null || :; done ) &
  echo "$!" > "$pidf"
  notify -u low "Caffeine on" "Screen stays awake"
fi
