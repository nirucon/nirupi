#!/usr/bin/env bash
# Isolated smoke tests; no graphical session, package manager or sudo required.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
export HOME="$WORK/home" XDG_STATE_HOME="$WORK/state"
mkdir -p "$HOME/.local/bin"
UPDATER="$ROOT/tools/update-statusbar.sh"
SOURCE="$ROOT/vendor/noir/local/bin/dwm-status.sh"
bash -n "$UPDATER" "$SOURCE"
bash "$UPDATER" --check | grep -q 'UPDATE available'
bash "$UPDATER" --apply | grep -q INSTALLED
cmp "$SOURCE" "$HOME/.local/bin/dwm-status.sh"
bash "$UPDATER" --check | grep -q 'already current'
printf '\n# local edit\n' >> "$HOME/.local/bin/dwm-status.sh"
if bash "$UPDATER" --apply >/dev/null 2>&1; then
  echo 'FAIL modified file overwritten' >&2; exit 1
fi
bash "$UPDATER" --adopt | grep -q INSTALLED
cmp "$SOURCE" "$HOME/.local/bin/dwm-status.sh"
find "$XDG_STATE_HOME/nirupi/statusbar-backups" -type f -name '*.bak' | grep -q .
echo 'PASS statusbar install, no-op, protection, explicit adoption and backup'
