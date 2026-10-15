#!/usr/bin/env bash
# NIRU: laptop lid-close behaviour via logind (systemd) or elogind.
#   nirupi lid        show the current setting; from a terminal, change it.
# Writes a drop-in (HandleLidSwitch=…) and restarts the logind service.
# Supports systemd-logind (/etc/systemd/logind.conf.d) and elogind
# (/etc/elogind/logind.conf.d, e.g. on Void).
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ if have notify-send; then notify-send -a NIRUPI "Lid" "$1" >/dev/null 2>&1; else printf 'Lid: %s\n' "$1"; fi; }
menu(){ if have rofi; then rofi -dmenu -i -p 'Lid close'; elif have dmenu; then dmenu -i -p 'Lid close'; else head -n1; fi; }

# Pick the logind flavour and where its drop-ins live.
if [[ -d /etc/elogind ]]; then
  kind=elogind; confdir=/etc/elogind/logind.conf.d; label='elogind'
elif [[ -e /etc/systemd/logind.conf || -d /etc/systemd ]]; then
  kind=systemd; confdir=/etc/systemd/logind.conf.d; label='systemd-logind'
else
  notify 'No systemd/elogind logind found (nothing to configure here)'
  exit 0
fi

cur="$( { grep -hs '^[[:space:]]*HandleLidSwitch=' \
           /etc/systemd/logind.conf /etc/systemd/logind.conf.d/*.conf \
           /etc/elogind/logind.conf  /etc/elogind/logind.conf.d/*.conf 2>/dev/null || true; } \
        | tail -n1 | cut -d= -f2 | tr -d ' ')"
printf 'Lid close: %s (%s)\n' "${cur:-suspend (logind default)}" "$label"

if [[ ! -t 0 ]]; then
  printf 'Run "nirupi lid" from a terminal (or the control center) to change it.\n'
  exit 0
fi

sel="$(printf 'lock\nsuspend\nignore\nsuspend-then-hibernate\nhybrid-sleep\n' | menu)" || exit 0
[[ -n $sel ]] || exit 0

printf 'Setting HandleLidSwitch=%s via %s (needs root) ...\n' "$sel" "$label"
sudo mkdir -p "$confdir"
printf '# Managed by nirupi (nirupi lid).\n[Login]\nHandleLidSwitch=%s\nHandleLidSwitchExternalPower=%s\nHandleLidSwitchDocked=ignore\n' \
  "$sel" "$sel" | sudo tee "$confdir/90-nirupi-lid.conf" >/dev/null
case "$kind" in
  systemd) sudo systemctl restart systemd-logind 2>/dev/null && ok=1 || ok=0;;
  elogind) if have sv; then sudo sv restart elogind 2>/dev/null && ok=1 || ok=0;
           else sudo systemctl restart elogind 2>/dev/null && ok=1 || ok=0; fi;;
esac
if [[ ${ok:-0} == 1 ]]; then
  notify "Lid close: $sel"
else
  notify "Set to $sel; restart $label to apply"
fi
