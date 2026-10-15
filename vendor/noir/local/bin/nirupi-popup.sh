#!/usr/bin/env bash
# nirupi-popup.sh [TITLE] — show a spec read on stdin.
#   default        : rofi/dmenu picker (selectable)
#   NIRUPI_POPUP=tui: a framed, palette-coloured TUI panel (nirupi-panel.py),
#                     always centred and sized to fit, closes on any key.
set -Eeuo pipefail

title="NIRUPI"
[[ -n ${1:-} ]] && title="$1"
spec="$(cat)"

# TUI panel mode.
if [[ "${NIRUPI_POPUP:-menu}" == tui ]] && command -v python3 >/dev/null 2>&1 \
   && [[ -x "$HOME/.local/bin/nirupi-panel.py" ]]; then
  cols=46
  lines="$(printf '%s\n' "$spec" | sed -n 's/^@\(row\|kv\|note\|title\|sub\) /\1 /p' | wc -l)"
  # width from the longest visible field, height from the number of lines
  longest="$(printf '%s\n' "$spec" | sed -E 's/^@[a-z]+ //' | awk '{print length}' | sort -rn | head -1)"
  [[ ${longest:-0} -gt 40 ]] && cols=$(( longest + 6 ))
  [[ $cols -gt 76 ]] && cols=76
  rows=$(( lines + 6 ))
  [[ $rows -lt 9 ]] && rows=9
  [[ $rows -gt 34 ]] && rows=34

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
          read -r sw sh < <(xdotool getdisplaygeometry 2>/dev/null || echo "1920 1080")
          eval "$(xdotool getwindowgeometry --shell "$wid" 2>/dev/null || true)"
          xdotool windowmove "$wid" "$(( (sw - ${WIDTH:-0}) / 2 ))" "$(( (sh - ${HEIGHT:-0}) / 2 ))" 2>/dev/null || true
        fi
      ) >/dev/null 2>&1 &
    fi
    if [[ "$(basename "$term")" == kitty ]]; then
      printf '%s\n' "$spec" | setsid kitty --class nirupi-info --title "$title" \
        --override remember_window_size=no \
        --override initial_window_width="${cols}c" --override initial_window_height="${rows}c" \
        --override font_size=13 \
        -e python3 "$HOME/.local/bin/nirupi-panel.py" >/dev/null 2>&1 &
    else
      printf '%s\n' "$spec" | setsid "$term" --title "$title" \
        -e python3 "$HOME/.local/bin/nirupi-panel.py" >/dev/null 2>&1 &
    fi
    exit 0
  fi
fi

# Picker mode.
printf '%s\n' "$spec" | sed -n 's/^@row /\1/p' >/dev/null 2>&1 || true
if command -v rofi >/dev/null 2>&1; then
  printf '%s\n' "$spec" | sed -n 's/^@\(row\|note\) /\1 /p' | sed 's/^row //; s/^note //' \
    | rofi -dmenu -i -p "$title"
elif command -v dmenu >/dev/null 2>&1; then
  printf '%s\n' "$spec" | sed -n 's/^@\(row\|note\) /\1 /p' | sed 's/^row //; s/^note //' \
    | dmenu -i -p "$title"
fi
