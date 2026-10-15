#!/usr/bin/env bash
# NIRU reload: rebuild dwm only when its sources changed, then restart it
# in place (no logout). Safe: a failed build keeps the running dwm.
# Usage: nirupi reload [--force]
set -Eeuo pipefail

force=0
[[ ${1:-} == --force ]] && force=1
LIB="$HOME/.local/lib/nirupi"
SRC="$LIB/src/suckless/dwm"
CFG="$HOME/.config/suckless/dwm/config.h"
BIN="$(readlink -f "$HOME/.local/bin/dwm" 2>/dev/null || true)"

[[ -d $SRC ]] || { printf 'dwm sources missing: %s\n' "$SRC" >&2; exit 1; }

need=0
if (( force )) || [[ -z $BIN || ! -x $BIN ]]; then
  need=1
else
  [[ -n "$(find "$SRC" -type f -newer "$BIN" -print -quit 2>/dev/null || true)" ]] && need=1
  [[ -f $CFG && $CFG -nt $BIN ]] && need=1
fi

if (( need )); then
  printf 'Rebuilding dwm…\n'
  if ! "$HOME/.local/bin/nirupi" migrate dwm --rebuild; then
    printf 'Rebuild failed; the running dwm is untouched.\n' >&2
    exit 1
  fi
else
  printf 'dwm is up to date (no rebuild needed).\n'
fi

if command -v pgrep >/dev/null 2>&1 && pgrep -x dwm >/dev/null 2>&1; then
  if command -v xdotool >/dev/null 2>&1; then
    if xdotool key --clearmodifiers super+ctrl+shift+r; then
      printf 'Restarted dwm in place.\n'
    else
      printf 'Could not trigger the restart; log out and back in.\n' >&2
    fi
  else
    printf 'xdotool not found; log out and back in to load the new dwm.\n' >&2
  fi
else
  printf 'dwm is not running; it will load on next login.\n'
fi
