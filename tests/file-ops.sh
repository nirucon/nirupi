#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
# lib/common.sh checks the real distribution and refuses root; test as normal user.
source "$ROOT/lib/common.sh"
BACKUP_DIR="$TMP/backups"
mkdir -p "$BACKUP_DIR" "$TMP/bin" "$TMP/src"
printf 'new\n' > "$TMP/src/a"
printf 'old\n' > "$TMP/bin/a"
put_file "$TMP/src/a" "$TMP/bin/a"
[[ $(cat "$TMP/bin/a") == new ]]
[[ $(cat "$BACKUP_DIR$TMP/bin/a") == old ]]
# An unrelated symlink must never be replaced.
ln -s /bin/true "$TMP/bin/foreign"
if (link_binary /bin/false "$TMP/bin/foreign") >/dev/null 2>&1; then
  echo 'FAIL: unmanaged symlink overwritten' >&2; exit 1
fi
[[ $(readlink "$TMP/bin/foreign") == /bin/true ]]
# A directory collision must fail rather than deleting the directory.
mkdir "$TMP/bin/collision"
if (put_file "$TMP/src/a" "$TMP/bin/collision") >/dev/null 2>&1; then
  echo 'FAIL: directory collision accepted' >&2; exit 1
fi
[[ -d $TMP/bin/collision ]]
echo 'PASS: actual file operations, backups and collision protection'
