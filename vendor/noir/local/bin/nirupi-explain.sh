#!/usr/bin/env bash
# NIRUPI explain — collect a compact, redacted system-health context and ask
# the AI agent to diagnose it. The context never leaves the machine unless you
# run the agent (which is explicit).
#
#   nirupi explain            collect + ask opencode
#   nirupi explain --print    print the redacted context only
#   nirupi explain --no-agent same as --print
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
say(){ printf '%s\n' "$*"; }
note(){ have notify-send && notify-send -a NIRUPI "$@" >/dev/null 2>&1 || :; }

redact(){
 sed -E \
  -e 's/((password|passwd|token|secret|api[_-]?key|authorization|bearer)[^=:[:space:]]*[=:][[:space:]]*)[^[:space:]]+/\1[REDACTED]/Ig' \
  -e 's/(-----BEGIN[^-]+-----).*/\1 [REDACTED]/g'
}

section(){ printf '\n## %s\n' "$1"; }

collect(){
 local distro session
 distro=unknown; session="${XDG_SESSION_TYPE:-unknown}"
 [[ -r /etc/os-release ]] && . /etc/os-release && distro="${PRETTY_NAME:-${ID:-unknown}}"

 printf '# NIRUPI health context\n'
 printf 'Date: %s\n' "$(date -Is 2>/dev/null || date)"
 printf 'Host: %s\n' "$(hostname 2>/dev/null || uname -n)"
 printf 'Distro: %s\n' "$distro"
 printf 'Kernel: %s\n' "$(uname -a)"
 printf 'Session: %s\n' "$session"

 section 'NIRUPI'
 if have nirupi; then
  printf 'version: %s\n' "$(nirupi version 2>/dev/null || true)"
  [[ -r "$HOME/.local/state/nirupi/installed.env" ]] && sed -n '1,20p' "$HOME/.local/state/nirupi/installed.env"
  nirupi doctor --json 2>/dev/null | head -c 6000 || true
 fi

 section 'Services'
 if have systemctl; then
  systemctl --failed --no-pager 2>/dev/null || true
  printf '\nRecent errors:\n'
  journalctl -b -p 3 --no-pager -n 120 2>/dev/null || true
 elif have sv; then
  for svc in /var/service/*; do
   [[ -e $svc ]] || continue
   sv status "$svc" 2>&1 | grep -v 'unable to open supervise/ok' || true
  done
  printf '\nRecent kernel messages:\n'
  dmesg -T 2>/dev/null | tail -n 100 || true
 fi

 section 'Hardware / desktop'
 have xrandr && xrandr --query 2>/dev/null | sed -n '1,40p'
 have wpctl && wpctl status 2>/dev/null | sed -n '1,80p'
 have nmcli && nmcli device status 2>/dev/null | sed -n '1,30p'
 have sensors && sensors 2>/dev/null | sed -n '1,60p'

 section 'Resources'
 df -h / /home 2>/dev/null || true
 free -h 2>/dev/null || true
 have zramctl && zramctl 2>/dev/null || true
 have swapon && swapon --show 2>/dev/null || true

 section 'Packages'
 if have pacman; then
  pacman -Qtdq 2>/dev/null | head -20 || true
  pacman -Qkk 2>/dev/null | grep -v '0 altered files' | head -20 || true
 elif have dpkg; then
  dpkg --audit 2>/dev/null | head -30 || true
 elif have xbps-pkgdb; then
  xbps-pkgdb -a 2>/dev/null | head -30 || true
 fi
}

context="$(collect 2>&1 | redact | head -c 24000)"
if [[ ${1:-} == --print || ${1:-} == --no-agent ]]; then
 printf '%s\n' "$context"
 exit 0
fi

have opencode || { note 'opencode is not installed'; printf '%s\n' "$context"; exit 1; }

prompt="You are a careful Linux troubleshooting assistant. Use ONLY the redacted context below. Identify the most likely root cause, give the smallest safe next commands, and explicitly separate facts from guesses. The system may be Void Linux (runit), Debian or Arch (systemd). Do not suggest disabling security features. Answer in English, concise, with a short checklist.

$context"

if [[ -t 0 && -t 1 ]]; then
 timeout 120 opencode run "$prompt" || note 'Agent failed; context printed above'
 exit 0
fi

term="$(command -v kitty || command -v alacritty || command -v st || true)"
if [[ -n $term ]]; then
 exec "$term" -e bash -lc 'timeout 120 opencode run "$1"' _ "$prompt"
fi
printf '%s\n' "$context"
note 'No terminal found; context printed/copied'
