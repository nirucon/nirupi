#!/usr/bin/env bash
# rofi "script mode" for the NIRU launcher: clipboard history.
# Called with no args -> print entries. Called with the chosen entry -> copy it.
set -Eeuo pipefail
hist="${XDG_CACHE_HOME:-$HOME/.cache}/clip-text.log"

copy(){
  if command -v wl-copy >/dev/null 2>&1 && [[ -n ${WAYLAND_DISPLAY:-} ]]; then wl-copy
  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -i
  else cat >/dev/null; fi
}

if [[ $# -eq 0 ]]; then
  [[ -s $hist ]] || exit 0
  tac "$hist" 2>/dev/null | awk -F'|' '{sub(/^[^|]*\|/,""); print}' \
    | awk 'length($0)>0 && !seen[$0]++' | head -n 40
  exit 0
fi

printf '%s' "$1" | copy
