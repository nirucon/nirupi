#!/usr/bin/env bash
# Lightweight automatic clipboard history (text). Appends changed clipboard
# content to ~/.cache/clip-text.log in the format used by clip-menu.sh
# ("timestamp | text"), de-duplicated and capped at CLIP_MAX entries.
set -Eeuo pipefail

command -v xclip >/dev/null 2>&1 || exit 0
HIST="${XDG_CACHE_HOME:-$HOME/.cache}/clip-text.log"
MAX="${NIRUPI_CLIP_MAX:-40}"
mkdir -p "$(dirname "$HIST")"; touch "$HIST"

last=""
while :; do
  cur="$(xclip -o -selection clipboard 2>/dev/null || :)"
  if [[ -n $cur && $cur != "$last" ]]; then
    last="$cur"
    one="$(printf '%s' "$cur" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-200)"
    if [[ "$(tail -n1 "$HIST" 2>/dev/null | cut -d'|' -f2- | sed 's/^[[:space:]]*//')" != "$one" ]]; then
      printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M')" "$one" >> "$HIST"
      tmp="$(mktemp)"
      tail -n "$MAX" "$HIST" > "$tmp" && mv "$tmp" "$HIST"
    fi
  fi
  sleep 1
done
