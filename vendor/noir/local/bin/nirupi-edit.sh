#!/usr/bin/env bash
# NIRU: open a NIRUPI config file in your editor.
#   nirupi edit              pick a topic (rofi/dmenu)
#   nirupi edit TOPIC        open it
#   nirupi edit --list       list topics
#   nirupi edit --path TOPIC print the resolved path (no editor)
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
c="${XDG_CONFIG_HOME:-$HOME/.config}"

topics=$(cat <<EOF
status|$c/nirupi/status.conf
session|$c/nirupi/session.conf
apps|$c/nirupi/apps.conf
agents|$c/nirupi/agents.conf
browser|$c/nirupi/browser.conf
wallpapers|$c/nirupi/wallpapers.conf
rules|$c/nirupi/rules.conf
missions|$c/nirupi/missions.conf
theme|$c/nirupi/tokens.env
dwm|$c/suckless/dwm/config.h
EOF
)

resolve(){ printf '%s\n' "$topics" | awk -F'|' -v t="$1" '$1==t{print $2; exit}'; }

case "${1:-}" in
  --list) printf '%s\n' "$topics" | awk -F'|' '{printf "  %-11s %s\n", $1, $2}'; exit 0;;
  --path)
    p="$(resolve "${2:-}")"
    [[ -n $p ]] || { printf 'Unknown topic: %s (try: nirupi edit --list)\n' "${2:-}" >&2; exit 2; }
    printf '%s\n' "$p"; exit 0;;
esac

topic="${1:-}"
if [[ -z $topic ]]; then
  topic="$(printf '%s\n' "$topics" | awk -F'|' '{print $1}' | \
    { if have rofi; then rofi -dmenu -i -p 'Edit config'; elif have dmenu; then dmenu -i -p 'Edit config'; else cat; fi; })" || true
  [[ -n $topic ]] || exit 0
fi

file="$(resolve "$topic")"
[[ -n $file ]] || { printf 'Unknown topic: %s (try: nirupi edit --list)\n' "$topic" >&2; exit 2; }

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
