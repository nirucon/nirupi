#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
for cmd in cc make pkg-config; do
 if ! command -v "$cmd" >/dev/null 2>&1; then
  printf 'MISSING executable: %s\n' "$cmd" >&2; fail=1
 fi
done
if command -v pkg-config >/dev/null 2>&1; then
 for lib in x11 xft xinerama fontconfig freetype2; do
  if pkg-config --exists "$lib"; then
   printf 'OK pkg-config: %s %s\n' "$lib" "$(pkg-config --modversion "$lib")"
  else
   printf 'MISSING pkg-config: %s\n' "$lib" >&2; fail=1
  fi
 done
fi
for app in dwm dmenu st slock; do
 [[ -f "$ROOT/vendor/suckless/$app/Makefile" ]] || { printf 'MISSING Makefile: %s\n' "$app" >&2; fail=1; }
done
if ((fail)); then
 printf 'BLOCKED: cannot verify full Suckless build on this machine\n' >&2
 exit 2
fi
printf 'PASS: build dependencies available; compile with tests/compile-suckless.sh\n'
