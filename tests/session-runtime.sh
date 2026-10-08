#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/.local/bin"
# A missing DWM must fail before any background process is launched.
if HOME="$TMP" DISPLAY=:99 sh "$ROOT/runtime-session.sh" >"$TMP/out" 2>&1; then
  echo 'FAIL: missing DWM accepted' >&2; exit 1
fi
grep -q 'DWM binary missing' "$TMP/out"
# A DWM binary is not sufficient without an X11 display.
printf '#!/bin/sh\nexit 0\n' > "$TMP/.local/bin/dwm"
chmod +x "$TMP/.local/bin/dwm"
if env -u DISPLAY HOME="$TMP" sh "$ROOT/runtime-session.sh" >"$TMP/out" 2>&1; then
  echo 'FAIL: missing DISPLAY accepted' >&2; exit 1
fi
grep -q 'DISPLAY is unset' "$TMP/out"
echo 'PASS: session startup fails safely before launching daemons'
