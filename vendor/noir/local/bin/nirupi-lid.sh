#!/usr/bin/env bash
# NIRU: laptop lid-close behaviour via systemd-logind.
#   nirupi lid        show the current setting; from a terminal, change it.
# Writes /etc/systemd/logind.conf.d/90-nirupi-lid.conf and restarts logind.
# Not applicable on systems without systemd-logind (e.g. Void/runit).
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ if have notify-send; then notify-send -a NIRUPI "Lid" "$1" >/dev/null 2>&1; else printf 'Lid: %s\n' "$1"; fi; }
menu(){ if have rofi; then rofi -dmenu -i -p 'Lid close'; elif have dmenu; then dmenu -i -p 'Lid close'; else head -n1; fi; }

if ! have loginctl && [[ ! -d /etc/systemd/logind.conf.d ]]; then
  notify 'systemd-logind not available (nothing to configure here)'
  exit 0
fi

cur="$( { grep -hs '^[[:space:]]*HandleLidSwitch=' /etc/systemd/logind.conf /etc/systemd/logind.conf.d/*.conf 2>/dev/null || true; } \
        | tail -n1 | cut -d= -f2 | tr -d ' ')"
printf 'Lid close: %s\n' "${cur:-suspend (logind default)}"

if [[ ! -t 0 ]]; then
  printf 'Run "nirupi lid" from a terminal (or the control center) to change it.\n'
  exit 0
fi

sel="$(printf 'lock\nsuspend\nignore\nsuspend-then-hibernate\nhybrid-sleep\n' | menu)" || exit 0
[[ -n $sel ]] || exit 0

printf 'Setting HandleLidSwitch=%s (needs root) ...\n' "$sel"
sudo mkdir -p /etc/systemd/logind.conf.d
printf '# Managed by nirupi (nirupi lid).\n[Login]\nHandleLidSwitch=%s\nHandleLidSwitchExternalPower=%s\nHandleLidSwitchDocked=ignore\n' \
  "$sel" "$sel" | sudo tee /etc/systemd/logind.conf.d/90-nirupi-lid.conf >/dev/null
if sudo systemctl restart systemd-logind 2>/dev/null; then
  notify "Lid close: $sel"
else
  notify "Set to $sel; reboot (or restart systemd-logind) to apply"
fi
