#!/usr/bin/env bash
# NIRU: open a NIRUPI config file in your editor.
#   nirupi edit            pick a topic (rofi/dmenu)
#   nirupi edit TOPIC      status|session|apps|agents|browser|wallpapers|theme|dwm
#   nirupi edit --list     list topics
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi"

topics="status:$cfg/status.conf
session:$cfg/session.conf
apps:$cfg/apps.conf
agents:$cfg/agents.conf
browser:$cfg/browser.conf
wallpapers:$cfg/wallpapers.conf
theme:$cfg/tokens.env
dwm:${XDG_CONFIG_HOME:-$HOME/.config}/suckless/dwm/config.h"

resolve(){
  local t="$1" line
  line="$(printf '%s\n' "$topics" | awk -F: -v t="$t" '$1==t{print $2":"$3; exit}')"
  [[ -n $line ]] || return 1
  printf '%s' "${line#*:}"
}

if [[ ${1:-} == --list ]]; then
  printf '%s\n' "$topics" | awk -F: '{printf "  %-11s %s\n", $1, $2":"$3}'
  exit 0
fi

topic="${1:-}"
if [[ -z $topic ]]; then
  topic="$(printf '%s\n' "$topics" | awk -F: '{print $1}' | \
    { if have rofi; then rofi -dmenu -i -p 'Edit config'; elif have dmenu; then dmenu -i -p 'Edit config'; else cat; fi; })" || true
  [[ -n $topic ]] || exit 0
fi

file="$(resolve "$topic")" || { printf 'Unknown topic: %s (try: nirupi edit --list)\n' "$topic" >&2; exit 2; }

if [[ ! -e $file ]]; then
  if [[ $topic == theme ]]; then
    printf 'No active palette file yet; run: nirupi theme set NAME\n' >&2; exit 1
  fi
  mkdir -p "$(dirname "$file")"; : > "$file"
  printf 'Created empty %s — save to keep it.\n' "$file" >&2
fi

editor="${VISUAL:-${EDITOR:-}}"
for e in "$editor" micro nano vi; do
  [[ -n $e ]] || continue
  if have "$e"; then editor="$e"; break; fi
done

# Needs a terminal: relaunch inside one when started from a menu.
if [[ ! -t 0 || ! -t 1 ]]; then
  for t in kitty alacritty st xterm; do
    if have "$t"; then exec "$t" -e "$0" "$topic"; fi
  done
  printf 'Open in your editor: %s\n' "$file"
  exit 0
fi

exec "$editor" "$file"
