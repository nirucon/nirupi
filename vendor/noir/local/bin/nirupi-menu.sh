#!/usr/bin/env bash
# NIRUPI control center — a single rofi/dmenu menu for common actions.
# Usage: nirupi-menu.sh [action]
set -Eeuo pipefail

rofi_bin="$(command -v rofi || true)"
dmenu_bin="$(command -v dmenu || true)"
term="$(command -v kitty || command -v alacritty || command -v st || true)"

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send "NIRUPI" "$*" || printf 'NIRUPI: %s\n' "$*"; }
theme_toggle(){
  local mf tf
  mf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/theme.mode"
  tf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/tokens.env"
  if [[ "$(cat "$mf" 2>/dev/null)" == wallpaper ]]; then
    exec nirupi theme mode noir
  elif [[ -f "$tf" ]]; then
    exec nirupi theme mode wallpaper
  else
    exec nirupi theme wallpaper
  fi
}
term_run(){ [[ -n "$term" ]] || { notify "No terminal found"; return 1; }; "$term" -- "$@"; }

power(){
  case "$1" in
    suspend) exec "$HOME/.local/bin/sleep-suspend.sh";;
    reboot) command -v loginctl >/dev/null 2>&1 && loginctl reboot || sudo reboot;;
    poweroff) command -v loginctl >/dev/null 2>&1 && loginctl poweroff || sudo poweroff;;
    logout) exec "$HOME/.local/bin/nirupi-logout.sh";;
  esac
}

choose(){
  if [[ -n "$rofi_bin" ]]; then "$rofi_bin" -dmenu -i -p 'NIRUPI'; 
  elif [[ -n "$dmenu_bin" ]]; then "$dmenu_bin" -i -p 'NIRUPI'; 
  else return 0; fi
}

wifi(){
  command -v nmcli >/dev/null 2>&1 || { notify 'nmcli not available'; return; }
  local ssid
  ssid="$(nmcli -t -f SSID device wifi list 2>/dev/null | awk 'NF && !seen[$0]++' | choose)" || return 0
  [[ -n "$ssid" ]] || return 0
  if nmcli -t device wifi connect "$ssid"; then notify "Connected to $ssid"; else
    read -r -s -p "Password for $ssid: " pw; echo
    nmcli device wifi connect "$ssid" password "$pw" && notify "Connected to $ssid" || notify 'Failed'
  fi
}

bluetooth(){
  command -v bluetoothctl >/dev/null 2>&1 || { notify 'bluetoothctl not available'; return; }
  local sel
  sel="$(printf '%s\n' 'power on' 'power off' 'scan on' 'paired devices' | choose)" || return 0
  case "$sel" in
    'power on') bluetoothctl power on;;
    'power off') bluetoothctl power off;;
    'scan on') bluetoothctl scan on;;
    'paired devices') bluetoothctl devices Paired | choose | awk '{print $2}' | xargs -r bluetoothctl connect;;
  esac
}

menu(){
  cat <<'EOF'
Lock screen
Suspend
Log out
Reboot
Shut down
Apply Noir theme
Wallpaper mode: toggle
Next wallpaper
Night light: toggle
Wi-Fi
Bluetooth
Weather
Mute / unmute
Agent (AI)
Backup configs
Check updates
EOF
}

action="${1:-}"
if [[ -z "$action" ]]; then
  action="$(menu | choose)" || exit 0
fi
case "$action" in
  'Lock screen') exec slock;;
  Suspend) power suspend;;
  'Log out') power logout;;
  Reboot) power reboot;;
  'Shut down') power poweroff;;
  'Apply Noir theme') exec nirupi theme apply;;
  'Wallpaper mode: toggle') theme_toggle;;
  'Next wallpaper') exec "$HOME/.local/bin/wallrotate.sh" next;;
  'Night light: toggle') exec "$HOME/.local/bin/nirupi-nightlight.sh";;
  'Wi-Fi') wifi;;
  Bluetooth) bluetooth;;
  Weather) exec xdg-open "https://www.yr.no/en/forecast/daily-table/2-2694503/Sweden/V%C3%A4stra%20G%C3%B6taland/Ljungskile" 2>/dev/null || true;;
  'Mute / unmute') wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null || amixer -q set Master toggle 2>/dev/null || true;;
  'Agent (AI)') exec nirupi-agent;;
  'Backup configs') exec nirupi backup;;
  'Check updates') n="$(nirupi updates --refresh >/dev/null 2>&1; nirupi updates 2>/dev/null)"; notify "Updates: ${n:-0}";;
  *) ;;
esac
