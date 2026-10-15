#!/usr/bin/env bash
# Dispatcher for clicks on the dwm status bar (statuscmd). dwm exports the
# pressed mouse button as $BUTTON (1 left, 2 middle, 3 right, 4 scroll up,
# 5 scroll down). Each action shows info or opens a small menu.
set -Eeuo pipefail
action="${1:-}"
ns(){ if command -v notify-send >/dev/null 2>&1; then notify-send -a NIRUPI "$@"; else printf 'NIRUPI: %s\n' "$*"; fi; }
open_dir(){ command -v pcmanfm >/dev/null 2>&1 && exec pcmanfm "$1" ; command -v xdg-open >/dev/null 2>&1 && exec xdg-open "$1"; }
# Resolve the media folders (same rules/defaults as the status bar; MEDIA_*_DIR
# in ~/.config/nirupi/status.conf overrides).
media_dir(){
  local kind="$1" d
  local conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/status.conf"
  [[ -r $conf ]] && . "$conf"
  case "$kind" in
    music)  for d in "${MEDIA_MUSIC_DIR:-}" "$HOME/Music" "$HOME/mp3" "$HOME/media/Music"; do [[ -n $d && -d $d ]] && { printf '%s' "$d"; return; }; done;;
    photos) for d in "${MEDIA_PHOTOS_DIR:-}" "$HOME/Pictures" "$HOME/Photos" "$HOME/media/Pictures"; do [[ -n $d && -d $d ]] && { printf '%s' "$d"; return; }; done;;
    videos) for d in "${MEDIA_VIDEOS_DIR:-}" "$HOME/Videos" "$HOME/media/Videos"; do [[ -n $d && -d $d ]] && { printf '%s' "$d"; return; }; done;;
  esac
  printf '%s' "$HOME"
}

case "$action" in
  # ── Launchers ──────────────────────────────────────────────────────────────
  agent)     exec "$HOME/.local/bin/nirupi-agent.sh";;
  menu)      exec "$HOME/.local/bin/nirupi-menu.sh";;
  keys)      exec "$HOME/.local/bin/nirupi-keys.sh";;
  bio)       exec "$HOME/.local/bin/nirupi-bluetooth.sh";;
  bluetooth) exec "$HOME/.local/bin/nirupi-bluetooth.sh";;

  # ── Network ────────────────────────────────────────────────────────────────
  network)
    if [[ "${BUTTON:-1}" == 3 ]]; then
      exec "$HOME/.local/bin/nirupi-net-popup.sh"
    else
      # Wired (or no Wi-Fi) -> info panel; Wi-Fi -> the network picker.
      dev_type="$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$3=="connected"{print $2; exit}')"
      if [[ $dev_type == wifi ]]; then
        exec "$HOME/.local/bin/nirupi-wifi.sh"
      else
        exec "$HOME/.local/bin/nirupi-net-popup.sh"
      fi
    fi;;

  # ── Media / audio ──────────────────────────────────────────────────────────
  media)      open_dir "$(media_dir music)";;
  photos)     open_dir "$(media_dir photos)";;
  videos)     open_dir "$(media_dir videos)";;
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
    exec "$HOME/.local/bin/nirupi-battery-popup.sh";;
  temp)
    exec "$HOME/.local/bin/nirupi-btop.sh";;
  memory) ns "Memory" "$(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2" used"}')";;
  uptime) ns "Uptime" "$(uptime -p 2>/dev/null || uptime)";;
  sysinfo) ns "Memory / Uptime" "$(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2" used"}')  ·  up $(uptime -p 2>/dev/null | sed 's/^up //' || uptime)";;
  disk)   exec "$HOME/.local/bin/nirupi-disk-popup.sh";;
  cpu)    ns "CPU" "$(ps -eo pcpu,comm --sort=-pcpu 2>/dev/null | sed -n '2,4p')";;
  load)   ns "Load" "$(cat /proc/loadavg 2>/dev/null) ($(nproc 2>/dev/null) cores)";;
  kernel) ns "Kernel" "$(uname -sr)";;
  host)   ns "Host" "$(cat /etc/hostname 2>/dev/null || uname -n 2>/dev/null) $({ hostname -I 2>/dev/null || ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | tr '\n' ' ' | sed 's/ *$//'; })";;
  date)   exec "$HOME/.local/bin/nirupi-calendar.sh";;
  time)   ns "$(date '+%H:%M')" "$(date '+%A %Y-%m-%d')";;

  # ── Updates / cloud / weather ──────────────────────────────────────────────
  updates)   exec "$HOME/.local/bin/nirupi-updates-popup.sh";;
  nextcloud) command -v nextcloud >/dev/null 2>&1 && exec nextcloud || ns "Nextcloud" "client not installed";;
  weather)   exec "$HOME/.local/bin/nirupi-weather-popup.sh";;
  *) exit 0;;
esac
