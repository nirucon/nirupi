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
      --override remember_window_size=no \
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
    # Guarantee a size that satisfies btop's 80x24 minimum, then centre.
    w=$(( sw * 72 / 100 )); h=$(( sh * 85 / 100 ))
    [[ $w -gt 1400 ]] && w=1400
    [[ $h -gt 1000 ]] && h=1000
    [[ ${WIDTH:-0} -lt "$(( sw * 60 / 100 ))" || ${HEIGHT:-0} -lt "$(( sh * 70 / 100 ))" ]] \
      && xdotool windowsize "$id" "$w" "$h" 2>/dev/null || true
    xdotool windowmove "$id" "$(( (sw - w) / 2 ))" "$(( (sh - h) / 2 ))" 2>/dev/null || true
  fi
fi
