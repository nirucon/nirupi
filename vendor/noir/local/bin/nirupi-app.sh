#!/usr/bin/env bash
# Launch one of the default ~/Git apps (nirunote/nplay/nirupresence) if installed.
# Terminal UIs (nplay, nirupresence) open inside a terminal (kitty/alacritty/st).
# If it is only present as a checkout, offer to run its installer.
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"

app="${1:-}"
notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }
[[ -n $app ]] || { printf 'usage: nirupi-app.sh NAME\n' >&2; exit 2; }

# Apps that are terminal UIs and must run inside a terminal.
case "$app" in
  nplay|nirupresence|cmus|btop|nvim|vim|micro) tui=1;;
  *) tui=0;;
esac
term="$(command -v kitty || command -v alacritty || command -v st || true)"

if command -v "$app" >/dev/null 2>&1; then
  if [[ $tui == 1 && -n $term ]]; then
    exec "$term" --title "$app" -e "$app"
  fi
  exec "$app"
fi
if [[ -x "$HOME/Git/$app/install.sh" ]]; then
  notify -u low "$app" "Not installed — running its installer"
  if [[ -n $term ]]; then
    exec "$term" --title "$app installer" -e bash -lc "cd \"$HOME/Git/$app\" && bash install.sh; printf '\nDone. Press Enter to close.'; read -r _"
  fi
  exit 0
fi
notify -u low "$app" "Not found (cd ~/Git and clone it)"
