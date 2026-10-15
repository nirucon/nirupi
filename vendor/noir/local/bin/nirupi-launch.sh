#!/usr/bin/env bash
# NIRU unified launcher: one rofi for apps (drun, incl. web apps), open windows,
# running a command, and the clipboard history. Bound to Super+Shift+p.
set -Eeuo pipefail
command -v rofi >/dev/null 2>&1 || { printf 'rofi not found\n' >&2; exit 1; }

clip="$HOME/.local/bin/nirupi-rofi-clip.sh"
if [[ -x $clip ]]; then
  exec rofi -show combi \
    -modi "window,drun,run,clip:$clip" \
    -combi-modi "window,drun,run,clip"
fi
exec rofi -show combi -combi-modi "window,drun,run"
