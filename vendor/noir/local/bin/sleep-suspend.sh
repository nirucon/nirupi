#!/usr/bin/env bash
# NIRUPI suspend helper: do not suspend an unlocked session.
set -Eeuo pipefail
command -v slock >/dev/null 2>&1 || { printf 'slock is not installed; refusing suspend without locking\n' >&2; exit 1; }
if ! command -v loginctl >/dev/null 2>&1 && ! command -v zzz >/dev/null 2>&1; then
  printf 'No supported suspend backend (loginctl or zzz)\n' >&2; exit 1
fi
command -v notify-send >/dev/null 2>&1 && notify-send -u low 'NIRUPI' 'Locking screen before suspend' || :
# Give slock a chance to map its window; refuse to suspend if it exits immediately.
slock &
locker=$!
sleep 1
if ! kill -0 "$locker" 2>/dev/null; then
  printf 'slock exited; refusing suspend\n' >&2
  wait "$locker" || :
  exit 1
fi
if command -v loginctl >/dev/null 2>&1; then
  loginctl suspend
else
  zzz
fi
