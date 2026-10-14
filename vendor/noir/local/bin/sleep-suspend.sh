#!/usr/bin/env bash
# NIRUPI suspend helper: lock the session, then suspend.
# The locker (slock) is setuid and drops privileges to an unprivileged user once
# running, so liveness must be checked with pgrep (ownership agnostic). A signal-0
# probe would return EPERM for another user's process and wrongly conclude death.
set -Eeuo pipefail

locker=""
if [[ -x "$HOME/.local/bin/nirupi-lock.sh" ]]; then
  locker="$HOME/.local/bin/nirupi-lock.sh"
elif command -v slock >/dev/null 2>&1; then
  locker="slock"
fi

suspend_backend(){
  if command -v loginctl >/dev/null 2>&1 && loginctl suspend; then exit 0; fi
  if command -v systemctl >/dev/null 2>&1 && systemctl suspend; then exit 0; fi
  if command -v zzz >/dev/null 2>&1 && zzz; then exit 0; fi
  printf 'No working suspend backend (loginctl/systemctl/zzz)\n' >&2
  exit 1
}

if [[ -z $locker ]]; then
  printf 'No screen locker found; suspending without locking\n' >&2
  suspend_backend
fi

command -v notify-send >/dev/null 2>&1 && notify-send -u low 'NIRUPI' 'Locking screen before suspend' || :

# Launch the locker detached so it survives this script's exit.
setsid "$locker" </dev/null >/dev/null 2>&1 &

# Wait until a slock process is actually holding the screen (max ~4s).
i=0
while (( i < 40 )); do
  pgrep -x slock >/dev/null 2>&1 && break
  sleep 0.1
  i=$((i + 1))
done
if ! pgrep -x slock >/dev/null 2>&1; then
  printf 'Screen locker did not start; refusing to suspend\n' >&2
  exit 1
fi

# Brief pause so the compositor commits the lock frame, then suspend.
sleep 0.4
suspend_backend
