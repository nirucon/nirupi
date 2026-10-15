#!/usr/bin/env bash
# nirupi-popup.sh [PROMPT] — show lines read on stdin in a floating rofi/dmenu
# and print the selection. Used by the status-bar pop-ups.
set -Eeuo pipefail
prompt="${1:-NIRUPI}"
if command -v rofi >/dev/null 2>&1; then
  exec rofi -dmenu -i -p "$prompt"
elif command -v dmenu >/dev/null 2>&1; then
  exec dmenu -i -p "$prompt"
else
  cat >/dev/null
fi
