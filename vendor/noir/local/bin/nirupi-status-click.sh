#!/usr/bin/env bash
# Dispatcher for clicks on the dwm status bar (statuscmd). dwm exports the
# pressed mouse button as $BUTTON (1 left, 2 middle, 3 right, 4 scroll up,
# 5 scroll down). Each action shows info or opens a small menu.
set -Eeuo pipefail
action="${1:-}"
ns(){ if command -v notify-send >/dev/null 2>&1; then notify-send -a NIRUPI "$@"; else printf 'NIRUPI: %s\n' "$*"; fi; }
open_dir(){ command -v pcmanfm >/dev/null 2>&1 && exec pcmanfm "$1" ; command -v xdg-open >/dev/null 2>&1 && exec xdg-open "$1"; }

case "$action" in
  # ── Launchers ──────────────────────────────────────────────────────────────
  agent)     exec "$HOME/.local/bin/nirupi-agent.sh";;
  menu)      exec "$HOME/.local/bin/nirupi-menu.sh";;
  keys)      exec "$HOME/.local/bin/nirupi-keys.sh";;
  bluetooth) exec "$HOME/.local/bin/nirupi-menu.sh" 'Bluetooth';;

  # ── Network ────────────────────────────────────────────────────────────────
  network)
    if [[ "${BUTTON:-1}" == 3 ]]; then
      ns "Network" "$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null; ip -brief addr show 2>/dev/null)"
    else
      exec "$HOME/.local/bin/nirupi-menu.sh" 'Wi-Fi'
    fi;;

  # ── Media / audio ──────────────────────────────────────────────────────────
  media)      open_dir "${NIRUPI_MUSIC_DIR:-$HOME/Music}";;
  nowplaying)
    if command -v playerctl >/dev/null 2>&1; then exec playerctl play-pause
    elif command -v cmus-remote >/dev/null 2>&1; then exec cmus-remote -C player-pause
    fi;;
  volume)
    case "${BUTTON:-1}" in
      4) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null || amixer -q set Master 5%+ 2>/dev/null || :;;
      5) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null || amixer -q set Master 5%- 2>/dev/null || :;;
      3) ns "Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || amixer get Master 2>/dev/null | awk -F'[][]' '/%/{print $2; exit}')";;
      *) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null || amixer -q set Master toggle 2>/dev/null || :;;
    esac;;
  mic) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null || ns "Microphone" "wpctl not available";;

  # ── Desktop state ──────────────────────────────────────────────────────────
  dnd) command -v dunstctl >/dev/null 2>&1 && dunstctl set-paused toggle || ns "Do not disturb" "dunstctl not available";;
  caffeine) exec "$HOME/.local/bin/nirupi-caffeine.sh";;
  recording) if [[ "${BUTTON:-1}" == 3 ]]; then exec "$HOME/.local/bin/nirupi-record.sh"; else open_dir "$HOME/Videos"; fi;;

  # ── System info ────────────────────────────────────────────────────────────
  battery)
    cap="$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)"
    st="$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)"
    ns "Battery" "${cap:-?}% ${st:-}";;
  temp)
    t="$(for f in /sys/class/hwmon/hwmon*/temp*_input; do cat "$f" 2>/dev/null; done | sort -n | tail -n1)"
    ns "Temperature" "$(( ${t:-0} / 1000 ))°C";;
  memory) ns "Memory" "$(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2" used"}')";;
  uptime) ns "Uptime" "$(uptime -p 2>/dev/null || uptime)";;
  disk)   ns "Disk" "$(df -h / 2>/dev/null | awk 'NR==2{print $5" used, "$4" free"}')";;
  cpu)    ns "CPU" "$(ps -eo pcpu,comm --sort=-pcpu 2>/dev/null | sed -n '2,4p')";;
  load)   ns "Load" "$(cat /proc/loadavg 2>/dev/null) ($(nproc 2>/dev/null) cores)";;
  kernel) ns "Kernel" "$(uname -sr)";;
  host)   ns "Host" "$(cat /etc/hostname 2>/dev/null || uname -n 2>/dev/null) $(hostname -I 2>/dev/null)";;
  date)   exec "$HOME/.local/bin/nirupi-calendar.sh";;
  time)   ns "$(date '+%H:%M')" "$(date '+%A %Y-%m-%d')";;

  # ── Updates / cloud / weather ──────────────────────────────────────────────
  updates)   exec "$HOME/.local/bin/nirupi-sysupdate.sh";;
  nextcloud) command -v nextcloud >/dev/null 2>&1 && exec nextcloud || ns "Nextcloud" "client not installed";;
  weather)   exec "$HOME/.local/bin/nirupi-menu.sh" 'Weather';;
  *) exit 0;;
esac
