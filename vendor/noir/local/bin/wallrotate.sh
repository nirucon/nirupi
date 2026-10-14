#!/bin/bash
# wallrotate.sh – Wallpaper daemon for DWM/X11 (via xinit)
# - No args  -> start daemon (15 min rotation)
# - next     -> immediate random wallpaper (random per monitor)
# - random   -> alias for next
set -euo pipefail

W="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}" # default dir
LOG="$HOME/.cache/wallrotate.log"
LOCK="$HOME/.cache/wallrotate.lock"
mkdir -p "$(dirname "$LOG")"

timestamp() { date '+%F %T'; }
log() { echo "$(timestamp) $*" >>"$LOG"; }

# Pick a random image (follows symlinks)
pick_random() {
  find -L "$W" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.bmp' -o -iname '*.webp' \) \
    2>/dev/null | shuf -n1
}

# Apply wallpaper to all monitors using feh
# Each monitor gets a random wallpaper (not the same image on all monitors)
apply_wallpaper() {
  # Detect connected monitors
  mapfile -t monitors < <(xrandr --listmonitors 2>/dev/null | awk 'NR>1 {print $NF}')
  
  if [ "${#monitors[@]}" -eq 0 ]; then
    log "⚠️  No monitors detected, falling back to default"
    local img="$(pick_random || true)"
    if [ -z "${img:-}" ]; then
      log "⚠️  No images found in $W"
      return 1
    fi
    log "🖼️  Setting wallpaper: $img"
    feh --no-fehbg --bg-fill "$img"
    return 0
  fi
  
  # Build feh command with random image per monitor
  local img_list=()
  
  for mon in "${monitors[@]}"; do
    local img="$(pick_random || true)"
    if [ -z "${img:-}" ]; then
      log "⚠️  No images found in $W"
      return 1
    fi
    img_list+=("$img")
  done
  
  # Log what we're setting
  log "🖼️  Setting wallpapers (${#monitors[@]} monitors):"
  for i in "${!monitors[@]}"; do
    log "   ${monitors[$i]}: ${img_list[$i]}"
  done
  
  # Execute feh with all images (feh handles monitor assignment automatically)
  feh --no-fehbg --bg-fill "${img_list[@]}"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [daemon|next|random]

  daemon       Start background rotation (default)
  next/random  Immediately switch to random wallpapers (different per monitor)

Environment:
  WALLPAPER_DIR  Override wallpaper folder (default: $HOME/Pictures/Wallpapers)
EOF
}

cmd="${1:-daemon}"
case "$cmd" in
next | random)
  apply_wallpaper
  exit $?
  ;;
daemon) ;;
*)
  usage
  exit 2
  ;;
esac

# Daemon mode – single instance via flock
command -v flock >/dev/null 2>&1 || { log "flock is required"; exit 1; }
exec 9>"$LOCK"
if ! flock -n 9; then
  log "ℹ️  wallrotate.sh already running; exiting."
  exit 0
fi

apply_wallpaper || true

# Rotate every 900 seconds (15 min) – stable timing
while :; do
  sleep 900 &
  spid=$!
  wait "$spid" 2>/dev/null || true
  apply_wallpaper || true
done
