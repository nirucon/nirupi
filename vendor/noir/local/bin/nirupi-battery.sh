#!/usr/bin/env bash
# NIRU battery guard (laptops). Warns at BATTERY_WARN%, warns critically and
# optionally suspends at BATTERY_CRIT%. Config in ~/.config/nirupi/session.conf:
#   BATTERY_WARN=15  BATTERY_CRIT=5  BATTERY_SUSPEND=0  BATTERY_POLL=60
set -Eeuo pipefail
conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/session.conf"
getv(){ [[ -f $conf ]] && sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$conf" 2>/dev/null | tail -n1 | tr -d '"'; }
WARN="${BATTERY_WARN:-$(getv BATTERY_WARN)}"; WARN="${WARN:-15}"
CRIT="${BATTERY_CRIT:-$(getv BATTERY_CRIT)}"; CRIT="${CRIT:-5}"
SUSPEND="${BATTERY_SUSPEND:-$(getv BATTERY_SUSPEND)}"; SUSPEND="${SUSPEND:-0}"
POLL="${BATTERY_POLL:-$(getv BATTERY_POLL)}"; POLL="${POLL:-60}"
[[ $WARN =~ ^[0-9]+$ ]] || WARN=15
[[ $CRIT =~ ^[0-9]+$ ]] || CRIT=5
[[ $POLL =~ ^[0-9]+$ ]] || POLL=60

bat="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)"
[[ -n ${bat:-} && -r $bat/capacity ]] || exit 0

note(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI -u "$1" "Battery" "$2" >/dev/null 2>&1 || :; }
suspend_now(){ if command -v systemctl >/dev/null 2>&1; then systemctl suspend; elif command -v loginctl >/dev/null 2>&1; then loginctl suspend; elif command -v zzz >/dev/null 2>&1; then zzz; fi; }

warned=0; critted=0
while :; do
  cap="$(cat "$bat/capacity" 2>/dev/null || echo 100)"
  status="$(cat "$bat/status" 2>/dev/null || echo Unknown)"
  if [[ $status == Discharging && $cap =~ ^[0-9]+$ ]]; then
    if (( cap <= CRIT )); then
      (( critted )) || { note critical "Battery critical (${cap}%) — connect power"; critted=1; }
      if [[ $SUSPEND == 1 ]]; then note normal "Suspending (${cap}%)"; suspend_now; critted=0; fi
    elif (( cap <= WARN )); then
      (( warned )) || { note normal "Battery low (${cap}%)"; warned=1; }
    fi
  else
    warned=0; critted=0
  fi
  sleep "$POLL"
done
