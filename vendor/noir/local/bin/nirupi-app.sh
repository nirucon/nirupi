#!/usr/bin/env bash
# Launch one of the default ~/Git apps (nirunote/nplay/nirupresence) if installed.
# If it is only present as a checkout, offer to run its installer.
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"

app="${1:-}"
notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }
[[ -n $app ]] || { printf 'usage: nirupi-app.sh NAME\n' >&2; exit 2; }

if command -v "$app" >/dev/null 2>&1; then
  exec "$app"
fi
if [[ -x "$HOME/Git/$app/install.sh" ]]; then
  notify -u low "$app" "Not installed — running its installer"
  if command -v kitty >/dev/null 2>&1; then
    exec kitty --title "$app installer" -e bash -lc "cd \"$HOME/Git/$app\" && bash install.sh; printf '\nDone. Press Enter to close.'; read -r _"
  fi
  exit 0
fi
notify -u low "$app" "Not found (cd ~/Git and clone it)"
