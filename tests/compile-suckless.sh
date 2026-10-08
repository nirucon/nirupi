#!/usr/bin/env bash
# Non-destructive real compilation in temporary directories, never "make install".
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/tests/build-dependencies.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
for app in dwm dmenu st slock; do
 mkdir -p "$TMP/$app"
 cp -a -- "$ROOT/vendor/suckless/$app/." "$TMP/$app/"
 printf 'BUILD %s\n' "$app"
 make -C "$TMP/$app" -j "$(nproc)"
 test -x "$TMP/$app/$app"
 printf 'PASS: compiled %s\n' "$app"
done
for helper in dmenu_run dmenu_path stest; do
 test -f "$TMP/dmenu/$helper"
done
printf 'PASS: all Suckless builds and dmenu helpers\n'
