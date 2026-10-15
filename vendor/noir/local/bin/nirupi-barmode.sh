#!/usr/bin/env bash
# Cycle the dwm bar: padded (default) -> full-bleed -> hidden.
# Also bound to Super+Ctrl+Shift+b; exposed for the control center and palette.
set -Eeuo pipefail
command -v xdotool >/dev/null 2>&1 || { printf 'xdotool required\n' >&2; exit 1; }
exec xdotool key --clearmodifiers super+ctrl+shift+b
