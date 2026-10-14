#!/usr/bin/env bash
# Day/night palette switching (monochrome but warmer at night).
#   nirupi-theme-auto.sh auto    # warm after 20:00 and before 07:00, else noir
#   nirupi-theme-auto.sh day     # force noir
#   nirupi-theme-auto.sh night   # force warm
# Schedule it if you like, e.g. a cron line:  0 * * * * ~/.local/bin/nirupi-theme-auto.sh auto
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"

mode="${1:-auto}"
case "$mode" in
  day)   pal=noir ;;
  night) pal=warm ;;
  auto)
    h="$(date +%H)"; h=$((10#$h))
    if (( h >= 20 || h < 7 )); then pal=warm; else pal=noir; fi ;;
  *) printf 'usage: nirupi-theme-auto.sh [auto|day|night]\n' >&2; exit 2 ;;
esac

exec nirupi theme set "$pal"
