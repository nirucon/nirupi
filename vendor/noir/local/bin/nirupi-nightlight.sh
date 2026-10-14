#!/usr/bin/env bash
# NIRU Noir night light. Super+n cycles 4500K -> 3500K -> 2500K -> off.
#   nirupi-nightlight.sh           cycle (default)
#   nirupi-nightlight.sh off|reset turn off and reset the gamma ramp
#   nirupi-nightlight.sh on        first warm level
# Multiple instances never stack: the shifter is killed before each change and
# the gamma ramp is reset explicitly, so toggling can't get "redder and redder".
set -Eeuo pipefail

state="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi/nightlight.level"
mkdir -p "$(dirname "$state")"
notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }

reset_gamma(){
  command -v xrandr >/dev/null 2>&1 || return 0
  local o
  for o in $(xrandr --query 2>/dev/null | awk '/ connected/{print $1}'); do
    xrandr --output "$o" --gamma 1:1:1 2>/dev/null || :
  done
}
stop_shifters(){ pkill -x gammastep 2>/dev/null || :; pkill -x redshift 2>/dev/null || :; sleep 0.2; }

apply(){ # kelvin
  stop_shifters
  reset_gamma
  if command -v gammastep >/dev/null 2>&1; then
    setsid gammastep -O "$1" >/dev/null 2>&1 &
  elif command -v redshift >/dev/null 2>&1; then
    setsid redshift -O "$1" >/dev/null 2>&1 &
  else
    notify "Install gammastep or redshift for night light"; return 1
  fi
  notify "Night light $1 K"
}

case "${1:-cycle}" in
  off|reset) stop_shifters; reset_gamma; printf '0\n' > "$state"; notify "Night light off"; exit 0;;
  on) apply "${NIRUPI_NIGHTLIGHT_TEMP:-4500}"; printf '1\n' > "$state"; exit 0;;
  cycle|toggle|'') : ;;
  *) printf 'usage: nirupi-nightlight.sh [cycle|on|off|reset]\n' >&2; exit 2;;
esac

lvl="$(cat "$state" 2>/dev/null || printf '0')"
case "$lvl" in ''|*[!0-9]*) lvl=0;; esac
lvl=$(( (lvl + 1) % 4 ))
printf '%s\n' "$lvl" > "$state"
case "$lvl" in
  0) stop_shifters; reset_gamma; notify "Night light off";;
  1) apply 4500;;
  2) apply 3500;;
  3) apply 2500;;
esac
