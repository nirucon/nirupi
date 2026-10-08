#!/bin/sh
# Shared X11 entry point for SDDM and startx.
export PATH="$HOME/.local/bin:$PATH"
# Validate before starting any background services.
if [ -z "${DISPLAY:-}" ]; then
  printf '%s\n' '[NIRUPI] DISPLAY is unset; launch via SDDM or startx' >&2
  exit 1
fi
if [ ! -x "$HOME/.local/bin/dwm" ]; then
  printf '%s\n' "[NIRUPI] DWM binary missing: $HOME/.local/bin/dwm" >&2
  exit 127
fi
[ -r "$HOME/.Xresources" ] && command -v xrdb >/dev/null 2>&1 && xrdb -merge "$HOME/.Xresources"
command -v setxkbmap >/dev/null 2>&1 && setxkbmap se
command -v xsetroot >/dev/null 2>&1 && xsetroot -solid '#111111'
STATUS_PID= WALL_PID= DUNST_PID=
if command -v dunst >/dev/null 2>&1 && ! pgrep -u "$(id -u)" -x dunst >/dev/null 2>&1; then dunst & DUNST_PID=$!; fi
if command -v dwm-status.sh >/dev/null 2>&1; then
  if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -f '[/]dwm-status.sh' >/dev/null 2>&1; then
    printf '%s\n' '[NIRUPI] Existing status process detected; skipping duplicate' >&2
  else
    dwm-status.sh & STATUS_PID=$!
  fi
fi
if command -v wallrotate.sh >/dev/null 2>&1; then
  if [ -d "${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}" ]; then
    wallrotate.sh & WALL_PID=$!
  fi
fi
cleanup() {
  for pid in "$STATUS_PID" "$WALL_PID" "$DUNST_PID"; do
    [ -z "$pid" ] || kill "$pid" 2>/dev/null || :
  done
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
"$HOME/.local/bin/dwm"
