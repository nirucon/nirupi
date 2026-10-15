#!/usr/bin/env bash
# NIRUPI control center — a single rofi/dmenu menu for common actions.
# Usage: nirupi-menu.sh [action]   (no action = interactive menu)
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"

rofi_bin="$(command -v rofi || true)"
dmenu_bin="$(command -v dmenu || true)"
xdo="$(command -v xdotool || true)"

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$*" || printf 'NIRUPI: %s\n' "$*"; }
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

power(){
  case "$1" in
    suspend) exec "$HOME/.local/bin/sleep-suspend.sh";;
    reboot) exec "$HOME/.local/bin/nirupi-power.sh" reboot;;
    poweroff) exec "$HOME/.local/bin/nirupi-power.sh" poweroff;;
    logout) exec "$HOME/.local/bin/nirupi-power.sh" logout;;
  esac
}

tailscale_toggle(){
  command -v tailscale >/dev/null 2>&1 || { notify 'tailscale not installed'; return 0; }
  if tailscale status >/dev/null 2>&1; then
    tailscale down && notify 'Tailscale: down' || notify 'Tailscale: could not disconnect'
  else
    if tailscale up 2>/dev/null || sudo -n tailscale up 2>/dev/null; then notify 'Tailscale: up'
    else notify 'Tailscale: run "sudo tailscale up" once'; fi
  fi
}

choose(){
  if [[ -n "$rofi_bin" ]]; then "$rofi_bin" -dmenu -i -p 'NIRUPI';
  elif [[ -n "$dmenu_bin" ]]; then "$dmenu_bin" -i -p 'NIRUPI';
  else return 0; fi
}

wifi(){
  command -v nmcli >/dev/null 2>&1 || { notify 'nmcli not available'; return 0; }
  local ssid
  ssid="$(nmcli -t -f SSID device wifi list 2>/dev/null | awk 'NF && !seen[$0]++' | choose)" || return 0
  [[ -n "$ssid" ]] || return 0
  if nmcli -t device wifi connect "$ssid"; then notify "Connected to $ssid"; else
    read -r -s -p "Password for $ssid: " pw; echo
    nmcli device wifi connect "$ssid" password "$pw" && notify "Connected to $ssid" || notify 'Failed'
  fi
}

bluetooth(){
  command -v bluetoothctl >/dev/null 2>&1 || { notify 'bluetoothctl not available'; return 0; }
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
Screensaver
Lock screen
Power menu…
Suspend
Log out
Reboot
Shut down
Keep awake (caffeine): toggle
Focus / notifications: toggle
Screen recording: toggle
Window switcher
Gaps: toggle (Super+g)
Keyboard layout (se/us)
Touchpad: toggle
Night light: cycle
Night light: off
Theme: choose…
Wallpaper mode: toggle
Next wallpaper
Wallpapers per workspace: toggle
Tailscale: toggle
Wi-Fi
Bluetooth
Audio output…
USB: mount/unmount…
Lid close…
Bar mode (padded/full/none)
Unsticky all windows
Apply screen layout
Weather
Calendar
Mute / unmute
Capture…
Emoji
Clipboard: transform
nirunote
nplay
nirupresence
Agent (AI)
Ask agent about screen…
AI command…
Notifications: history…
SSH / host…
Reload desktop…
Edit config…
System update
Backup configs
Check updates
EOF
}

action="${1:-}"
if [[ -z "$action" ]]; then
  action="$(menu | choose)" || exit 0
fi
case "$action" in
  Screensaver) exec "$HOME/.local/bin/nirupi-lock.sh" -s;;
  'Lock screen') exec "$HOME/.local/bin/nirupi-lock.sh";;
  'Power menu…') exec "$HOME/.local/bin/nirupi-power.sh";;
  Suspend) power suspend;;
  'Log out') power logout;;
  Reboot) power reboot;;
  'Shut down') power poweroff;;
  'Keep awake (caffeine): toggle') exec "$HOME/.local/bin/nirupi-caffeine.sh";;
  'Focus / notifications: toggle') exec "$HOME/.local/bin/nirupi-focus.sh";;
  'Screen recording: toggle') exec "$HOME/.local/bin/nirupi-record.sh";;
  'Window switcher') exec "$HOME/.local/bin/nirupi-window.sh";;
  'Gaps: toggle (Super+g)') [[ -n "$xdo" ]] && "$xdo" key --clearmodifiers super+g && notify 'Gaps toggled (Super+g to undo)' || notify 'xdotool missing';;
  'Keyboard layout (se/us)') exec "$HOME/.local/bin/nirupi-keyboard.sh";;
  'Touchpad: toggle') exec "$HOME/.local/bin/nirupi-touchpad.sh";;
  'Night light: cycle') exec "$HOME/.local/bin/nirupi-nightlight.sh";;
  'Night light: off') exec "$HOME/.local/bin/nirupi-nightlight.sh" off;;
  'Theme: choose…') exec nirupi theme menu;;
  'Wallpaper mode: toggle') theme_toggle;;
  'Next wallpaper') exec "$HOME/.local/bin/wallrotate.sh" next;;
  'Wallpapers per workspace: toggle') exec "$HOME/.local/bin/nirupi-wallpaper.sh" per-tag toggle;;
  'Tailscale: toggle') tailscale_toggle;;
  'Wi-Fi') wifi;;
  Bluetooth) bluetooth;;
  'Audio output…') exec "$HOME/.local/bin/nirupi-audio.sh";;
  'USB: mount/unmount…') exec "$HOME/.local/bin/nirupi-usb.sh";;
  'Lid close…') if command -v kitty >/dev/null 2>&1; then exec kitty -e "$HOME/.local/bin/nirupi-lid.sh"; else exec "$HOME/.local/bin/nirupi-lid.sh"; fi;;
  'Bar mode (padded/full/none)') exec "$HOME/.local/bin/nirupi-barmode.sh";;
  'Unsticky all windows') [[ -n "$xdo" ]] && "$xdo" key --clearmodifiers super+ctrl+alt+shift+s && notify 'Sticky cleared (all windows)' || notify 'xdotool missing';;
  'Apply screen layout') exec "$HOME/.local/bin/apply-screenlayout.sh";;
  Weather) exec xdg-open "https://www.smhi.se/vader/prognoser/ortsprognoser/?lat=58.2167&lon=11.9333" 2>/dev/null || true;;
  Calendar) exec "$HOME/.local/bin/nirupi-calendar.sh";;
  'System update') exec "$HOME/.local/bin/nirupi-sysupdate.sh";;
  'Mute / unmute') exec "$HOME/.local/bin/nirupi-osd.sh" volume mute;;
  'Capture…') exec "$HOME/.local/bin/nirupi-capture.sh";;
  Emoji) exec "$HOME/.local/bin/nirupi-emoji.sh";;
  'Clipboard: transform') exec "$HOME/.local/bin/nirupi-clip-transform.sh";;
  nirunote) exec "$HOME/.local/bin/nirupi-app.sh" nirunote;;
  nplay) exec "$HOME/.local/bin/nirupi-app.sh" nplay;;
  nirupresence) exec "$HOME/.local/bin/nirupi-app.sh" nirupresence;;
  'Agent (AI)') exec nirupi-agent;;
  'Ask agent about screen…') exec "$HOME/.local/bin/nirupi-agent-screen.sh";;
  'AI command…') exec "$HOME/.local/bin/nirupi-ask-command.sh";;
  'Notifications: history…') exec "$HOME/.local/bin/nirupi-notifications.sh";;
  'SSH / host…') exec "$HOME/.local/bin/nirupi-ssh.sh";;
  'Reload desktop…') exec "$HOME/.local/bin/nirupi-reload.sh";;
  'Edit config…') exec "$HOME/.local/bin/nirupi-edit.sh";;
  'Backup configs') exec nirupi backup;;
  'Check updates') n="$(nirupi updates --refresh >/dev/null 2>&1; nirupi updates 2>/dev/null)"; notify "Updates: ${n:-0}";;
  *) ;;
esac
