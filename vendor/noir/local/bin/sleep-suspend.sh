#!/usr/bin/env bash
# NIRUPI suspend helper: lock the screen, wait a few seconds, then suspend.
#
# The screen is locked immediately so nothing is left exposed. During the short
# grace period you can change your mind: unlocking (which ends slock) cancels the
# suspend. slock is setuid and drops to an unprivileged user, so liveness is
# checked with pgrep (ownership-agnostic); a signal-0 probe would see EPERM.
set -Eeuo pipefail

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }

# Grace period (seconds) before suspend; 0 suspends immediately. Configurable
# via the environment or ~/.config/nirupi/session.conf.
SUSPEND_DELAY_SECONDS="${SUSPEND_DELAY_SECONDS:-3}"
conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/session.conf"
# shellcheck disable=SC1090
[ -r "$conf" ] && . "$conf"
SUSPEND_DELAY_SECONDS="${SUSPEND_DELAY_SECONDS:-3}"
case "$SUSPEND_DELAY_SECONDS" in ''|*[!0-9]*) SUSPEND_DELAY_SECONDS=3;; esac

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

setsid "$locker" </dev/null >/dev/null 2>&1 &

# Wait until slock actually holds the screen (max ~4s).
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

# Grace period: cancel the suspend if the user unlocks during it.
if (( SUSPEND_DELAY_SECONDS > 0 )); then
  i=0
  while (( i < SUSPEND_DELAY_SECONDS * 10 )); do
    if ! pgrep -x slock >/dev/null 2>&1; then
      notify -u low -t 4000 'Suspend cancelled'
      exit 0
    fi
    sleep 0.1
    i=$((i + 1))
  done
fi

suspend_backend
