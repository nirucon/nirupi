#!/usr/bin/env bash
# Status-bar pop-up: list pending system updates; pick "Update now" to run the
# distro updater. Read-only otherwise.
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"
have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ if have notify-send; then notify-send -a NIRUPI "Updates" "$1"; else printf 'Updates: %s\n' "$1"; fi; }

pending(){
  if have checkupdates; then checkupdates 2>/dev/null
  elif have pacman; then pacman -Qu 2>/dev/null
  elif have apt-get; then LC_ALL=C apt list --upgradable 2>/dev/null | awk -F/ 'NR>1{print $1}'
  elif have xbps-install; then xbps-install -un 2>/dev/null
  fi
}

rows="$(pending || true)"
sel="$( { printf '\342\226\266 Update now\n'; [[ -n $rows ]] && printf '%s\n' "$rows"; } \
        | "$HOME/.local/bin/nirupi-popup.sh" 'Updates' )" || true
case "$sel" in
  *'Update now') exec "$HOME/.local/bin/nirupi-sysupdate.sh";;
  '') [[ -n $rows ]] || notify 'No updates pending' ;;
esac
