#!/usr/bin/env bash
# nirupi-popup.sh [TITLE] — show lines read on stdin in a floating panel.
# Default: a rofi/dmenu list (selectable). With NIRUPI_POPUP=tui it shows a
# centred read-only terminal (kitty) for nicer info panels (battery, weather).
set -Eeuo pipefail

title="NIRUPI"
[[ -n ${1:-} ]] && title="$1"

if [[ "${NIRUPI_POPUP:-menu}" == tui ]]; then
  term="$(command -v kitty || command -v alacritty || command -v st || true)"
  if [[ -n $term ]]; then
    body="$(cat)"
    tmp="$(mktemp)"
    printf '%s\n' "$body" > "$tmp"
    # centre once mapped (dwm floats it via the nirupi-info rule)
    if command -v xdotool >/dev/null 2>&1; then
      (
        for _ in $(seq 1 60); do
          wid="$(xdotool search --class nirupi-info 2>/dev/null | tail -1 || true)"
          [[ -n $wid ]] && break
          sleep 0.1
        done
        if [[ -n ${wid:-} ]]; then
          read -r sw sh < <(xdotool getdisplaygeometry 2>/dev/null || echo "1920 1080")
          eval "$(xdotool getwindowgeometry --shell "$wid" 2>/dev/null || true)"
          xdotool windowmove "$wid" "$(( (sw - ${WIDTH:-0}) / 2 ))" "$(( (sh - ${HEIGHT:-0}) / 2 ))" 2>/dev/null || true
        fi
      ) >/dev/null 2>&1 &
    fi
    if [[ "$(basename "$term")" == kitty ]]; then
      setsid kitty --class nirupi-info --title "$title" \
        --override remember_window_size=no \
        --override initial_window_width=64c --override initial_window_height=22c \
        --override font_size=13 \
        -e bash -lc 'clear; printf "\n"; sed "s/^/  /" "$1"; printf "\n\n  Press any key to close.\n"; IFS= read -rn1 -s _; rm -f "$1"' _ "$tmp" >/dev/null 2>&1 &
    else
      setsid "$term" --title "$title" -e bash -c 'sed "s/^/  /" "$1"; read -rn1 _; rm -f "$1"' _ "$tmp" >/dev/null 2>&1 &
    fi
    exit 0
  fi
  # fall through to menu if no terminal
fi

if command -v rofi >/dev/null 2>&1; then
  exec rofi -dmenu -i -p "$title"
elif command -v dmenu >/dev/null 2>&1; then
  exec dmenu -i -p "$title"
else
  cat >/dev/null
fi
