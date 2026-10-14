#!/bin/sh
# NIRU Noir logout confirmation. Shows a small rofi/dmenu prompt before quitting
# DWM (which ends the X session). Bind to Super+Shift+q instead of quitting
# immediately.
export PATH="$HOME/.local/bin:$PATH"

prompt='Log out?'
if command -v rofi >/dev/null 2>&1; then
  choice="$(printf 'Log out\nCancel\n' | rofi -dmenu -i -p "$prompt" -theme-str 'window { width: 260px; }' 2>/dev/null || printf 'Cancel\n')"
elif command -v dmenu >/dev/null 2>&1; then
  choice="$(printf 'Log out\nCancel\n' | dmenu -i -p "$prompt" 2>/dev/null || printf 'Cancel\n')"
elif command -v kitty >/dev/null 2>&1; then
  printf 'Log out? [y/N] ' >&2
  read -r answer
  case "$answer" in y|Y|yes|YES) choice='Log out';; *) choice='Cancel';; esac
else
  choice='Cancel'
fi

case "$choice" in
  'Log out') pkill -x dwm ;;
  *) exit 0 ;;
esac
