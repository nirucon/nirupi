#!/usr/bin/env bash
# Minimal NIRU Noir on-screen indicator for volume / brightness / mic.
# Uses one reusable dunst notification (canonical-private-synchronous) so the
# level updates in place instead of stacking. Monochrome block bar, no graphs.
#   nirupi-osd.sh volume up|down|mute
#   nirupi-osd.sh mic mute
#   nirupi-osd.sh brightness up|down
set -Eeuo pipefail

kind="${1:-}"; dir="${2:-}"
notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }

bar(){
  local pct="$1" out="" i n
  (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
  n=$(( pct / 10 ))
  for (( i = 0; i < 10; i++ )); do
    if (( i < n )); then out+="█"; else out+="░"; fi
  done
  printf '%s' "$out"
}

osd(){ # pct label
  notify -h string:x-canonical-private-synchronous:nirupi-osd \
         -h int:value:"$1" -u low "$2" "$(bar "$1")  $1%"
}

sink_pct(){ wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d", $2*100}'; }

case "$kind" in
  volume)
    command -v wpctl >/dev/null 2>&1 || { notify -u low "Volume" "wpctl missing"; exit 0; }
    case "$dir" in
      up)   wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
      down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
      mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
      *) exit 2 ;;
    esac
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED; then
      osd 0 "Volume (muted)"
    else
      osd "$(sink_pct)" "Volume"
    fi ;;
  mic)
    command -v wpctl >/dev/null 2>&1 || { notify -u low "Microphone" "wpctl missing"; exit 0; }
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; then
      notify -h string:x-canonical-private-synchronous:nirupi-osd -u low "Microphone" "Muted"
    else
      notify -h string:x-canonical-private-synchronous:nirupi-osd -u low "Microphone" "Live"
    fi ;;
  brightness)
    command -v brightnessctl >/dev/null 2>&1 || { notify -u low "Brightness" "brightnessctl missing"; exit 0; }
    case "$dir" in
      up)   brightnessctl -q set +5% ;;
      down) brightnessctl -q set 5%- ;;
      *) exit 2 ;;
    esac
    p="$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); printf "%d", $4}')"
    osd "${p:-0}" "Brightness" ;;
  *) printf 'usage: nirupi-osd.sh {volume|mic|brightness} {up|down|mute}\n' >&2; exit 2 ;;
esac
