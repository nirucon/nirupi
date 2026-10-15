#!/usr/bin/env bash
# Toggle the touchpad on/off with xinput (laptop-friendly).
#
# Note: `xinput list --name-only` prefixes a DISABLED device with a marker
# (e.g. "∼ "), so re-enabling by name fails. We therefore look the device up by
# its numeric id, which is stable regardless of enabled/disabled state.
set -Eeuo pipefail

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }
command -v xinput >/dev/null 2>&1 || { notify -u low "Touchpad" "xinput missing"; exit 0; }

id="$(xinput list 2>/dev/null \
  | grep -iE 'touchpad|trackpad|synaptics' \
  | grep -oE 'id=[0-9]+' | head -n1 | cut -d= -f2)"
[[ -n $id ]] || { notify -u low "Touchpad" "No touchpad found"; exit 0; }

en="$(xinput list-props "$id" 2>/dev/null | awk '/Device Enabled/{print $NF}' | head -n1)"
if [[ $en == 1 ]]; then
  xinput disable "$id" && notify -u low "Touchpad" "Disabled"
elif [[ $en == 0 ]]; then
  xinput enable "$id" && notify -u low "Touchpad" "Enabled"
else
  notify -u low "Touchpad" "No 'Device Enabled' property"
fi
