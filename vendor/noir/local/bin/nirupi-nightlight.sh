#!/bin/sh
# NIRU Noir night-light toggle. Uses gammastep (preferred) or redshift. Runs in
# the background; toggling again turns it off. Optional — never fatal.
export PATH="$HOME/.local/bin:$PATH"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "NIRUPI" "$*" || printf 'NIRUPI: %s\n' "$*"; }

running=0
pgrep -x gammastep >/dev/null 2>&1 && running=1
pgrep -x redshift  >/dev/null 2>&1 && running=1

if [ "$running" = 1 ]; then
  pkill -x gammastep 2>/dev/null || :
  pkill -x redshift  2>/dev/null || :
  notify 'Night light off'
  exit 0
fi

temp="${NIRUPI_NIGHTLIGHT_TEMP:-4000}"
if command -v gammastep >/dev/null 2>&1; then
  setsid gammastep -O "$temp" >/dev/null 2>&1 &
elif command -v redshift >/dev/null 2>&1; then
  setsid redshift -O "$temp" >/dev/null 2>&1 &
else
  notify 'Install gammastep or redshift for night light'
  exit 1
fi
notify "Night light on (${temp}K)"
