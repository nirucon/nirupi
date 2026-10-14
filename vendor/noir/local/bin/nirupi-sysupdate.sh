#!/usr/bin/env bash
# Open the distro's system update in a centred floating terminal.
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"
# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null || true
case "${ID:-} ${ID_LIKE:-}" in
  *debian*|*ubuntu*) cmd='sudo apt-get update && sudo apt-get full-upgrade && sudo apt-get autoremove';;
  *void*) cmd='sudo xbps-install -Syu';;
  *arch*) cmd='sudo pacman -Syu';;
  *) cmd='echo "Unknown distribution — run your updater manually"';;
esac
term="$(command -v kitty || command -v alacritty || command -v st || true)"
[ -n "$term" ] || exit 1
run="printf 'NIRU Noir — system update\n\n'; $cmd; printf '\n\nDone. Press Enter to close.'; read -r _"
case "$(basename "$term")" in
  kitty)
    exec kitty --class nirupi-update --title nirupi-update \
      --override initial_window_width=104c --override initial_window_height=34c \
      -e bash -lc "$run" ;;
  *)
    exec "$term" --title nirupi-update -e bash -lc "$run" ;;
esac
