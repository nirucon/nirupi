#!/usr/bin/env bash
# Status-bar pop-up: Bluetooth. When the adapter is off (or absent) it shows a
# framed info panel; when it is on it offers a picker of known/available devices
# plus the connected one first — consistent with the Wi-Fi picker.
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ if have notify-send; then notify-send -a NIRUPI "Bluetooth" "$1"; else printf 'Bluetooth: %s\n' "$1"; fi; }
pick(){ if have rofi; then rofi -dmenu -i -p 'Bluetooth'; elif have dmenu; then dmenu -i -p 'Bluetooth'; else head -n1; fi; }
panel(){ NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Bluetooth >/dev/null 2>&1 || true; }

have bluetoothctl || { printf '@title Bluetooth\n@sub unavailable\n@note bluetoothctl not installed.\n' | panel; exit 0; }

powered="$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')"
adapter="$(bluetoothctl list 2>/dev/null | awk 'NR==1{print $2}')"
if [[ $powered != yes ]]; then
  {
    printf '@title Bluetooth\n@sub %s\n' "${adapter:-no adapter}"
    printf '@accent muted\n'
    printf '@note Adapter is off.\n'
    printf '@note Run: bluetoothctl power on\n'
  } | panel
  exit 0
fi

connected="$(bluetoothctl devices Connected 2>/dev/null | sed 's/^Device //')"
rows=()
if [[ -n $connected ]]; then
  while IFS= read -r line; do
    mac="${line%% *}"; name="${line#* }"
    rows+=("● $name  ($mac)  connected")
  done <<< "$connected"
fi
while IFS= read -r line; do
  mac="${line%% *}"; name="${line#* }"
  grep -q "$mac" <<< "$connected" && continue
  rows+=("  $name  ($mac)")
done < <(bluetoothctl devices 2>/dev/null | sed 's/^Device //')

[[ ${#rows[@]} -gt 0 ]] || rows+=("(no known devices)")
rows+=("⟳ Scan 60s" "⊘ Disable adapter")

sel="$(printf '%s\n' "${rows[@]}" | pick)" || exit 0
[[ -n $sel ]] || exit 0
case "$sel" in
  '⟳ Scan'*) exec "$0" --scan;;
  '⊘ Disable'*) bluetoothctl power off >/dev/null 2>&1 && notify 'Adapter off'; exit 0;;
esac
mac="$(printf '%s' "$sel" | grep -oE '([0-9A-F]{2}:){5}[0-9A-F]{2}')"
[[ -n $mac ]] || exit 0
if grep -q 'connected' <<< "$sel"; then
  bluetoothctl disconnect "$mac" >/dev/null 2>&1 && notify 'Disconnected' || notify 'Could not disconnect'
else
  bluetoothctl connect "$mac" >/dev/null 2>&1 && notify 'Connected' || notify 'Could not connect'
fi
