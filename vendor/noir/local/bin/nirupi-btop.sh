#!/usr/bin/env bash
# Status-bar pop-up: btop in a floating, centred terminal (temp/CPU click).
# btop needs at least 80x24, so we request a comfortable size and centre the
# window once it appears (dwm floats it via the nirupi-btop rule).
set -Eeuo pipefail
term="$(command -v kitty || command -v alacritty || command -v st || true)"
[[ -n $term ]] || { printf 'no terminal found\n' >&2; exit 1; }

case "$(basename "$term")" in
  kitty)
    setsid kitty --class nirupi-btop --title btop \
      --override initial_window_width=110c --override initial_window_height=34c \
      -e btop >/dev/null 2>&1 &
    ;;
  *)
    setsid "$term" --title btop -e btop >/dev/null 2>&1 &
    ;;
esac

# Centre the window once it maps.
if command -v xdotool >/dev/null 2>&1; then
  for _ in $(seq 1 60); do
    id="$(xdotool search --class nirupi-btop 2>/dev/null | head -1 || true)"
    [[ -n $id ]] && break
    sleep 0.1
  done
  if [[ -n ${id:-} ]]; then
    read -r sw sh < <(xdotool getdisplaygeometry 2>/dev/null || echo "1920 1080")
    eval "$(xdotool getwindowgeometry --shell "$id" 2>/dev/null || true)"
    if [[ ${WIDTH:-0} -gt 0 && ${HEIGHT:-0} -gt 0 ]]; then
      xdotool windowmove "$id" "$(( (sw - WIDTH) / 2 ))" "$(( (sh - HEIGHT) / 2 ))" 2>/dev/null || true
    fi
  fi
fi
