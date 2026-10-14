#!/usr/bin/env bash
# Minimal window switcher: rofi -show window, falling back to xdotool+dmenu.
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"

if command -v rofi >/dev/null 2>&1; then
  exec rofi -show window
fi

if command -v dmenu >/dev/null 2>&1 && command -v xdotool >/dev/null 2>&1; then
  sel="$(xdotool search --onlyvisible --name '.' 2>/dev/null | while read -r w; do
    n="$(xdotool getwindowname "$w" 2>/dev/null)" || continue
    [[ -n $n ]] && printf '%s\t%s\n' "$n" "$w"
  done | dmenu -i -l 12 -p 'Window')"
  [[ -n $sel ]] || exit 0
  win="${sel##*$'\t'}"
  xdotool windowactivate "$win" 2>/dev/null || :
fi
