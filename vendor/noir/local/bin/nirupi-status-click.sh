#!/usr/bin/env bash
# Dispatcher for clicks on the dwm status bar (statuscmd). dwm exports the
# pressed mouse button as $BUTTON (1 left, 2 middle, 3 right, 4 up, 5 down).
set -Eeuo pipefail
action="${1:-}"
case "$action" in
  agent)     exec "$HOME/.local/bin/nirupi-agent.sh";;
  menu)      exec "$HOME/.local/bin/nirupi-menu.sh";;
  keys)      exec "$HOME/.local/bin/nirupi-keys.sh";;
  weather)   exec "$HOME/.local/bin/nirupi-menu.sh" 'Weather';;
  updates)   exec "$HOME/.local/bin/nirupi-menu.sh" 'Check updates';;
  nextcloud) command -v nextcloud >/dev/null 2>&1 && exec nextcloud || exit 0;;
  network)   exec "$HOME/.local/bin/nirupi-menu.sh" 'Wi-Fi';;
  volume)
    case "${BUTTON:-1}" in
      4) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null || amixer -q set Master 5%+ 2>/dev/null || :;;
      5) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null || amixer -q set Master 5%- 2>/dev/null || :;;
      *) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null || amixer -q set Master toggle 2>/dev/null || :;;
    esac;;
  *) exit 0;;
esac
