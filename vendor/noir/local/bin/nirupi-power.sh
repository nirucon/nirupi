#!/usr/bin/env bash
# NIRU Noir power menu (Super+Shift+q). Distro-portable (loginctl -> systemctl
# -> sudo) with optional timers and a cancel option.
#   nirupi-power.sh            interactive menu
#   nirupi-power.sh lock|screensaver|suspend|reboot|poweroff|logout|cancel
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"

notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }
timerfile="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi/power.timer"

choose(){
  if command -v rofi >/dev/null 2>&1; then rofi -dmenu -i -p 'Power';
  elif command -v dmenu >/dev/null 2>&1; then dmenu -i -p 'Power';
  else cat >/dev/null; fi
}
ask_minutes(){
  local a
  if command -v rofi >/dev/null 2>&1; then a="$(printf '%s\n' 5 10 15 30 60 | rofi -dmenu -i -p 'Minutes')";
  elif command -v dmenu >/dev/null 2>&1; then a="$(printf '%s\n' 5 10 15 30 60 | dmenu -i -p 'Minutes')";
  else a=''; fi
  case "$a" in ''|*[!0-9]*) printf 'cancel';; *) printf '%s' "$a";; esac
}

do_suspend(){ if command -v loginctl >/dev/null 2>&1; then loginctl suspend && return; fi
  if command -v systemctl >/dev/null 2>&1; then systemctl suspend && return; fi
  if command -v zzz >/dev/null 2>&1; then sudo zzz; fi; }
do_reboot(){ if command -v loginctl >/dev/null 2>&1; then loginctl reboot && return; fi
  if command -v systemctl >/dev/null 2>&1; then systemctl reboot && return; fi
  sudo reboot; }
do_poweroff(){ if command -v loginctl >/dev/null 2>&1; then loginctl poweroff && return; fi
  if command -v systemctl >/dev/null 2>&1; then systemctl poweroff && return; fi
  sudo poweroff; }
do_logout(){ pkill -x dwm; }

cancel_timer(){
  [[ -f $timerfile ]] || return 0
  local pid _
  read -r pid _ < "$timerfile" || :
  [[ -n ${pid:-} ]] && kill "$pid" 2>/dev/null || :
  rm -f "$timerfile"
  notify -u low "Scheduled action cancelled"
}
schedule(){ # action minutes
  local action="$1" minutes="$2"
  cancel_timer >/dev/null 2>&1 || true
  mkdir -p "$(dirname "$timerfile")"
  ( sleep "$((minutes * 60))"; case "$action" in suspend) do_suspend;; reboot) do_reboot;; poweroff) do_poweroff;; esac ) &
  echo "$! $action $minutes" > "$timerfile"
  case "$action" in suspend) label=Suspend;; reboot) label=Reboot;; *) label='Shut down';; esac
  notify -u low "$label in ${minutes} min" "Cancel: Super+Shift+q"
}

# Non-interactive actions (reused by the control center).
case "${1:-}" in
  lock) exec "$HOME/.local/bin/nirupi-lock.sh";;
  screensaver) exec "$HOME/.local/bin/nirupi-lock.sh" -s;;
  suspend) do_suspend; exit 0;;
  reboot) do_reboot; exit 0;;
  poweroff) do_poweroff; exit 0;;
  logout) do_logout; exit 0;;
  cancel) cancel_timer; exit 0;;
  '') : ;;
  *) printf 'usage: nirupi-power.sh [lock|screensaver|suspend|reboot|poweroff|logout|cancel]\n' >&2; exit 2;;
esac

menu(){ cat <<'EOF'
Screensaver
Lock screen
Suspend
Suspend in 15 minutes
Suspend in 30 minutes
Suspend in 60 minutes
Suspend in … (choose minutes)
Log out
Reboot
Reboot in 15 minutes
Reboot in 30 minutes
Reboot in 60 minutes
Reboot in … (choose minutes)
Shut down
Shut down in 15 minutes
Shut down in 30 minutes
Shut down in 60 minutes
Shut down in … (choose minutes)
Cancel scheduled action
Cancel
EOF
}

sel="$(menu | choose)" || exit 0
case "$sel" in
  Screensaver) exec "$HOME/.local/bin/nirupi-lock.sh" -s;;
  'Lock screen') exec "$HOME/.local/bin/nirupi-lock.sh";;
  Suspend) do_suspend;;
  'Suspend in 15 minutes') schedule suspend 15;;
  'Suspend in 30 minutes') schedule suspend 30;;
  'Suspend in 60 minutes') schedule suspend 60;;
  'Suspend in … (choose minutes)') m="$(ask_minutes)"; [[ $m == cancel ]] || schedule suspend "$m";;
  'Log out') do_logout;;
  Reboot) do_reboot;;
  'Reboot in 15 minutes') schedule reboot 15;;
  'Reboot in 30 minutes') schedule reboot 30;;
  'Reboot in 60 minutes') schedule reboot 60;;
  'Reboot in … (choose minutes)') m="$(ask_minutes)"; [[ $m == cancel ]] || schedule reboot "$m";;
  'Shut down') do_poweroff;;
  'Shut down in 15 minutes') schedule poweroff 15;;
  'Shut down in 30 minutes') schedule poweroff 30;;
  'Shut down in 60 minutes') schedule poweroff 60;;
  'Shut down in … (choose minutes)') m="$(ask_minutes)"; [[ $m == cancel ]] || schedule poweroff "$m";;
  'Cancel scheduled action') cancel_timer;;
  *) exit 0;;
esac
