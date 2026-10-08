#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="$ROOT/runtime-session.sh"
WALL="$ROOT/vendor/noir/local/bin/wallrotate.sh"
BAR="$ROOT/vendor/noir/local/bin/dwm-status.sh"
grep -Fq '${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}' "$SESSION"
grep -Fq 'W="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"' "$WALL"
grep -Fq 'flock -n 9 || exit 0' "$BAR"
grep -Fq '[[ -n "${kernel:-}" ]] && parts+=("$kernel")' "$BAR"
if grep -Fq 'parts+=("$kernel" "$host" "$datepart" "$timepart")' "$BAR"; then
  echo 'FAIL: status bar can add empty segments' >&2; exit 1
fi
printf 'PASS: desktop integration and statusbar guards\n'
