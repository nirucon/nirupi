#!/usr/bin/env bash
# Focus mode: pause notifications (do-not-disturb) with a single toggle.
set -Eeuo pipefail

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }

if command -v dunstctl >/dev/null 2>&1; then
  if [[ "$(dunstctl is-paused 2>/dev/null)" == "true" ]]; then
    dunstctl set-paused false
    notify -u low "Focus off" "Notifications resumed"
  else
    dunstctl set-paused true
    notify -u low "Focus on" "Notifications paused until toggled off"
  fi
else
  notify -u low "Focus" "dunstctl not available (install dunst)"
fi
