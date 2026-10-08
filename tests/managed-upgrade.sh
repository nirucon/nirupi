#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" STATE="$TMP/state" BACKUP_DIR="$TMP/backups/run"
mkdir -p "$HOME/.local/bin" "$STATE" "$BACKUP_DIR"
# Source isolated functions without invoking OS-detection/root restrictions.
eval "$(sed -n '/^backup_file(){/,/^}/p; /^put_file(){/,/^}/p' "$ROOT/lib/common.sh")"
source "$ROOT/lib/managed.sh"
die(){ echo "$*" >&2; exit 1; }
warn(){ echo "$*" >&2; }
SRC="$TMP/source"; DEST="$HOME/.local/bin/test-helper.sh"
printf '#!/bin/sh\necho one\n' > "$SRC"
managed_helper_install test-helper.sh "$SRC" "$DEST"
[[ -x $DEST ]] && grep -q 'echo one' "$DEST"
[[ $(wc -l < "$STATE/managed-helpers.tsv") -eq 1 ]]
printf '#!/bin/sh\necho two\n' > "$SRC"
managed_helper_install test-helper.sh "$SRC" "$DEST"
grep -q 'echo two' "$DEST"
[[ $(wc -l < "$STATE/managed-helpers.tsv") -eq 1 ]]
# Identical content with wrong permissions should restore the executable bit.
chmod 0644 "$DEST"
managed_helper_install test-helper.sh "$SRC" "$DEST"
[[ -x $DEST ]]
# Local edits must survive a later release.
printf '# user edit\n' >> "$DEST"
printf '#!/bin/sh\necho three\n' > "$SRC"
managed_helper_install test-helper.sh "$SRC" "$DEST"
grep -q '# user edit' "$DEST"
! grep -q 'echo three' "$DEST"
# Foreign untracked helper must survive untouched.
printf 'foreign\n' > "$HOME/.local/bin/foreign.sh"
managed_helper_install foreign.sh "$SRC" "$HOME/.local/bin/foreign.sh"
grep -qx 'foreign' "$HOME/.local/bin/foreign.sh"
# Foreign symlink must survive untouched.
ln -s "$DEST" "$HOME/.local/bin/link.sh"
managed_helper_install link.sh "$SRC" "$HOME/.local/bin/link.sh"
[[ -L "$HOME/.local/bin/link.sh" ]]
# Backups of managed changes must exist.
[[ -s "$BACKUP_DIR/manifest.txt" ]]
echo 'PASS: managed helper install, upgrade, permissions, user edits, symlinks and backup'
