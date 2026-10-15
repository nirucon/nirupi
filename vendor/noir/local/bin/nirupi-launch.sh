#!/usr/bin/env bash
# NIRU unified launcher: one rofi for apps (drun, incl. web apps), open windows,
# running a command, the clipboard history, and file search. Bound to Super+Shift+p.
set -Eeuo pipefail
command -v rofi >/dev/null 2>&1 || { printf 'rofi not found\n' >&2; exit 1; }

modi="window,drun,run"
combi="window,drun,run"
clip="$HOME/.local/bin/nirupi-rofi-clip.sh"
files="$HOME/.local/bin/nirupi-rofi-files.sh"
if [[ -x $clip ]]; then  modi="$modi,clip:$clip";   combi="$combi,clip";  fi
if [[ -x $files ]]; then modi="$modi,files:$files"; combi="$combi,files"; fi

exec rofi -show combi -modi "$modi" -combi-modi "$combi"
