#!/usr/bin/env bash
# Toggle the touchpad on/off with xinput (laptop-friendly).
set -Eeuo pipefail

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }
command -v xinput >/dev/null 2>&1 || { notify -u low "Touchpad" "xinput missing"; exit 0; }

dev="$(xinput list --name-only 2>/dev/null | grep -iE 'touchpad|trackpad|synaptics' | head -n1)"
[[ -n $dev ]] || { notify -u low "Touchpad" "No touchpad found"; exit 0; }

en="$(xinput list-props "$dev" 2>/dev/null | awk '/Device Enabled/{print $NF}' | head -n1)"
if [[ $en == 1 ]]; then
  xinput disable "$dev" && notify -u low "Touchpad" "Disabled"
elif [[ $en == 0 ]]; then
  xinput enable "$dev" && notify -u low "Touchpad" "Enabled"
else
  notify -u low "Touchpad" "No 'Device Enabled' property"
fi
