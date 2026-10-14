#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" XDG_STATE_HOME="$TMP/home/.local/state"
mkdir -p "$HOME/.local/bin" "$HOME/.config/suckless/dwm" "$HOME/.ssh"
printf 'personal dwm config\n' > "$HOME/.config/suckless/dwm/config.h"
printf 'keep ssh\n' > "$HOME/.ssh/config"
printf 'old dwm\n' > "$HOME/.local/bin/dwm"
ln -s /bin/true "$HOME/.local/bin/st"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/managed.sh"
source "$ROOT/lib/migrate.sh"
source "$ROOT/lib/release.sh"
source "$ROOT/lib/rollback.sh"
VERSION=9.9.9; DISTRO=debian; SESSION=startx

# State tracking
write_installed_state
[[ "$(read_installed_state NIRUPI_VERSION)" == 9.9.9 ]]
[[ "$(read_installed_state NIRUPI_SCHEMA)" == "$NIRUPI_SCHEMA" ]]
[[ -f "$STATE/installed.env" ]]

# Read-only report lists legacy artifacts and never modifies anything.
migration_report > "$TMP/report"
grep -Fq "$HOME/.local/bin/dwm" "$TMP/report"
grep -Fq "$HOME/.config/suckless/dwm/config.h" "$TMP/report"
[[ -f "$HOME/.local/bin/dwm" && -L "$HOME/.local/bin/st" ]]

# Explicit apply archives foreign binaries instead of crashing.
run=20260101-000000-1
resolve_binary_conflicts "$run"
[[ ! -e "$HOME/.local/bin/dwm" && ! -L "$HOME/.local/bin/st" ]]
[[ -f "$STATE/legacy/$run/.local/bin/dwm" ]]
[[ -L "$STATE/legacy/$run/.local/bin/st" ]]
[[ "$(cat "$STATE/legacy/$run/.local/bin/dwm")" == 'old dwm' ]]
[[ "$(cat "$HOME/.ssh/config")" == 'keep ssh' ]]

# Backup + unified config rollback (interactive path via pseudo-TTY).
BACKUP_DIR="$STATE/backups/20260101-000000-2"; mkdir -p "$BACKUP_DIR"
printf 'original\n' > "$HOME/.config/example.conf"
backup_file "$HOME/.config/example.conf"
[[ "$(cat "$BACKUP_DIR$HOME/.config/example.conf")" == original ]]
printf 'user-changed\n' > "$HOME/.config/example.conf"
printf 'ROLLBACK\n' | script -q -e -c \
  "env HOME='$HOME' XDG_STATE_HOME='$XDG_STATE_HOME' ROOT='$ROOT' bash -c 'source \$ROOT/lib/common.sh; source \$ROOT/lib/managed.sh; source \$ROOT/lib/release.sh; source \$ROOT/lib/rollback.sh; restore_config_backup 20260101-000000-2'" \
  "$TMP/rollback.log" >/dev/null
[[ "$(cat "$HOME/.config/example.conf")" == original ]]

# Unsafe backup manifests are rejected before any change.
[[ "$(cat "$TMP/report")" == *'never deleted'* ]]
echo 'PASS: migration state, legacy archival and unified config rollback'
