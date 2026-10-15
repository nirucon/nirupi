#!/usr/bin/env bash
# nirupi-popup.sh [TITLE] — show a spec read on stdin.
#   default         : rofi/dmenu picker (selectable)
#   NIRUPI_POPUP=tui: a framed, palette-coloured TUI panel (nirupi-panel.py),
#                     sized to the content and centred, closes on any key.
set -Eeuo pipefail

title="NIRUPI"
[[ -n ${1:-} ]] && title="$1"
spec="$(cat)"

if [[ "${NIRUPI_POPUP:-menu}" == tui ]] && command -v python3 >/dev/null 2>&1 \
   && [[ -x "$HOME/.local/bin/nirupi-panel.py" ]]; then
  # size the window from the content (cols/rows; kitty 0.48 ignores
  # initial_window_width/height overrides)
  longest="$(printf '%s\n' "$spec" | sed -E 's/^@[a-z]+ //' | sed 's/|/  /g' | awk '{print length}' | sort -rn | head -1)"
  items="$(printf '%s\n' "$spec" | grep -cE '^@(row|note|sub) |^[^@]')"
  cols=$(( ${longest:-30} + 6 )); [[ $cols -lt 34 ]] && cols=34; [[ $cols -gt 74 ]] && cols=74
  rows=$(( items + 6 )); [[ $rows -lt 9 ]] && rows=9; [[ $rows -gt 32 ]] && rows=32

  term="$(command -v kitty || command -v alacritty || command -v st || true)"
  if [[ -n $term ]]; then
    if command -v xdotool >/dev/null 2>&1; then
      (
        for _ in $(seq 1 60); do
          wid="$(xdotool search --class nirupi-info 2>/dev/null | tail -1 || true)"
          [[ -n $wid ]] && break
          sleep 0.1
        done
        if [[ -n ${wid:-} ]]; then
          # let dwm place the float first, then centre on the monitor
          sleep 0.2
          read -r monx mony monw monh < <(xdotool getdisplaygeometry 2>/dev/null | awk '{print 0,0,$1,$2}' || echo "0 0 1920 1080")
          eval "$(xdotool getwindowgeometry --shell "$wid" 2>/dev/null || true)"
          xdotool windowmove "$wid" "$(( monx + (monw - ${WIDTH:-0}) / 2 ))" "$(( mony + (monh - ${HEIGHT:-0}) / 2 ))" 2>/dev/null || true
        fi
      ) >/dev/null 2>&1 &
    fi
    if [[ "$(basename "$term")" == kitty ]]; then
      printf '%s\n' "$spec" | setsid kitty --class nirupi-info --title "$title" \
        --override remember_window_size=no \
        -e python3 "$HOME/.local/bin/nirupi-panel.py" >/dev/null 2>&1 &
    else
      printf '%s\n' "$spec" | setsid "$term" --title "$title" \
        -e python3 "$HOME/.local/bin/nirupi-panel.py" >/dev/null 2>&1 &
    fi
    exit 0
  fi
fi

# Picker mode.
if command -v rofi >/dev/null 2>&1; then
  printf '%s\n' "$spec" | sed -n 's/^@row //p; s/^@note //p; s/^@sub //p' | rofi -dmenu -i -p "$title"
elif command -v dmenu >/dev/null 2>&1; then
  printf '%s\n' "$spec" | sed -n 's/^@row //p; s/^@note //p; s/^@sub //p' | dmenu -i -p "$title"
fi
