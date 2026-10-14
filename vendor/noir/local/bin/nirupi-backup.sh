#!/usr/bin/env bash
# Back up NIRUPI-managed user configuration into a single tarball.
# Destination: ~/Nextcloud/nirupi-backups when a Nextcloud folder exists,
# otherwise ~/.local/state/nirupi/backups/.
set -Eeuo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nirupi"
nextcloud=""
for d in "$HOME/Nextcloud" "$HOME/nextcloud" "$HOME/Nextcloud2"; do
  [[ -d "$d" ]] && { nextcloud="$d"; break; }
done
if [[ -n "$nextcloud" ]]; then dest="$nextcloud/nirupi-backups"; else dest="$STATE/backups"; fi
mkdir -p "$dest"
archive="$dest/nirupi-config-$STAMP.tar.gz"

paths=()
for p in \
  "$HOME/.config/nirupi" \
  "$HOME/.config/suckless" \
  "$HOME/.config/kitty" "$HOME/.config/alacritty" "$HOME/.config/tmux" \
  "$HOME/.config/lazygit" "$HOME/.config/micro" "$HOME/.config/aerc" \
  "$HOME/.config/dunst" "$HOME/.config/picom" "$HOME/.config/rofi" \
  "$HOME/.config/fish/config.fish" \
  "$HOME/.Xresources" "$HOME/.xinitrc" "$HOME/.gtkrc-2.0"; do
  [[ -e "$p" ]] && paths+=("${p#"$HOME"/}")
done

[[ ${#paths[@]} -gt 0 ]] || { echo 'Nothing to back up' >&2; exit 0; }
tar -czf "$archive" -C "$HOME" "${paths[@]}"
printf 'Backup written: %s\n' "$archive"
command -v notify-send >/dev/null 2>&1 && notify-send "NIRUPI" "Backup klar: $archive"
