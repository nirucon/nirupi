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
  battery)
    cap="$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)"
    st="$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)"
    command -v notify-send >/dev/null 2>&1 && notify-send "Battery" "${cap:-?}% ${st:-}" ; exit 0;;
  temp)
    t="$(for f in /sys/class/hwmon/hwmon*/temp*_input; do cat "$f" 2>/dev/null; done | sort -n | tail -n1)"
    command -v notify-send >/dev/null 2>&1 && notify-send "Temperature" "$(( ${t:-0} / 1000 ))°C"; exit 0;;
  volume)
    case "${BUTTON:-1}" in
      4) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null || amixer -q set Master 5%+ 2>/dev/null || :;;
      5) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null || amixer -q set Master 5%- 2>/dev/null || :;;
      *) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null || amixer -q set Master toggle 2>/dev/null || :;;
    esac;;
  *) exit 0;;
esac
