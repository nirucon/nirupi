#!/bin/sh
# Open the NIRU Noir calendar TUI in a centred floating terminal.
export PATH="$HOME/.local/bin:$PATH"
app="$HOME/.local/bin/nirupi-calendar.py"
term="$(command -v kitty || command -v alacritty || command -v st || true)"
[ -n "$term" ] || exit 1
case "$(basename "$term")" in
  kitty)
    exec kitty --class nirupi-calendar --title nirupi-calendar \
      --override remember_window_size=no \
      --override initial_window_width=72c --override initial_window_height=24c \
      -e python3 "$app" ;;
  *)
    exec "$term" --title nirupi-calendar -e python3 "$app" ;;
esac
