#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" XDG_STATE_HOME="$TMP/state"
mkdir -p "$HOME" "$XDG_STATE_HOME"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/managed.sh"
RUN_ID=fixture; BACKUP_DIR="$STATE/backups/$RUN_ID"; mkdir -p "$BACKUP_DIR"
SRC="$TMP/source"; DEST="$HOME/.config/dwm/config.h"
printf 'original\n' > "$SRC"
managed_config_install dwm/config.h "$SRC" "$DEST"
[[ $(cat "$DEST") == original ]]
[[ $(wc -l < "$STATE/managed-configs.tsv") -eq 1 ]]
printf 'updated\n' > "$SRC"
managed_config_install dwm/config.h "$SRC" "$DEST"
[[ $(cat "$DEST") == updated ]]
[[ -f "$BACKUP_DIR$DEST" ]]
[[ $(wc -l < "$STATE/managed-configs.tsv") -eq 1 ]]
printf 'personal\n' > "$DEST"
printf 'newer\n' > "$SRC"
managed_config_install dwm/config.h "$SRC" "$DEST"
[[ $(cat "$DEST") == personal ]]
printf 'foreign\n' > "$HOME/.config/foreign"
managed_config_install foreign "$SRC" "$HOME/.config/foreign"
[[ $(cat "$HOME/.config/foreign") == foreign ]]
ln -s "$SRC" "$HOME/.config/symlink"
managed_config_install symlink "$SRC" "$HOME/.config/symlink"
[[ -L "$HOME/.config/symlink" ]]
# An existing untracked xinitrc must never be overwritten.
printf 'exec my-window-manager\n' > "$HOME/.xinitrc"
managed_config_install session/xinitrc "$SRC" "$HOME/.xinitrc" 0755
[[ $(cat "$HOME/.xinitrc") == 'exec my-window-manager' ]]
# A tracked executable should have its mode repaired.
EXE="$HOME/.local/bin/nirupi-session"
managed_config_install session/nirupi-session "$SRC" "$EXE" 0755
chmod 0644 "$EXE"
managed_config_install session/nirupi-session "$SRC" "$EXE" 0755
[[ -x "$EXE" ]]
echo 'PASS: managed configs upgrade, backup, preserve modifications/symlinks and repair mode'
