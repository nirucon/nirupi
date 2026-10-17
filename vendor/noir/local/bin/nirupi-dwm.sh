#!/usr/bin/env bash
# NIRUPI dwm control helper — scriptable access to the running window manager.
# It drives the same keybindings you use manually, so it stays small and safe.
#
#   nirupi dwm state              show the saved layout state
#   nirupi dwm tag N              switch to tag 1-9
#   nirupi dwm layout NAME        right|left|float|monocle|center|centerfloat|fib
#   nirupi dwm gaps|bar|scratchpad|restart
#   nirupi dwm send KEY           send a raw Super+KEY binding
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
die(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }
have xdotool || die 'xdotool is required'

key(){ xdotool key --clearmodifiers "$1"; }

case "${1:-state}" in
 state)
  f="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi/dwm.state"
  [[ -r $f ]] && cat "$f" || printf 'No saved dwm state yet\n';;
 tag)
  n="${2:-}"
  [[ $n =~ ^[1-9]$ ]] || die 'Usage: nirupi dwm tag 1-9'
  key "super+$n";;
 layout)
  case "${2:-}" in
   right|rstack|stack) key super+t;;
   left|tileleft) key super+y;;
   float|floating) key super+f;;
   monocle) key super+m;;
   center|centered) key super+c;;
   centerfloat|centeredfloat) key super+u;;
   fib|fibonacci|dwindle) key super+ctrl+e;;
   *) die 'Usage: nirupi dwm layout right|left|float|monocle|center|centerfloat|fib';;
  esac;;
 gaps) key super+g;;
 bar) key super+ctrl+shift+b;;
 scratchpad) key super+shift+s;;
 restart) key super+ctrl+shift+r;;
 send)
  [[ -n ${2:-} ]] || die 'Usage: nirupi dwm send KEY (e.g. b)'
  key "super+$2";;
 -h|--help) sed -n '1,14p' "$0";;
 *) die 'Usage: nirupi dwm state|tag N|layout NAME|gaps|bar|scratchpad|restart|send KEY';;
esac
