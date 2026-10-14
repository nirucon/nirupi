#!/usr/bin/env bash
# Toggle the keyboard layout between Swedish (se) and US (us).
set -Eeuo pipefail

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }
command -v setxkbmap >/dev/null 2>&1 || { notify -u low "Keyboard" "setxkbmap missing"; exit 0; }

state="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi/kbd"
cur="$(cat "$state" 2>/dev/null || printf 'se')"
[[ $cur == se ]] && next=us || next=se

if setxkbmap "$next" 2>/dev/null; then
  mkdir -p "$(dirname "$state")"
  printf '%s\n' "$next" > "$state"
  notify -u low "Keyboard layout" "$next"
else
  notify -u low "Keyboard layout" "Could not switch"
fi
