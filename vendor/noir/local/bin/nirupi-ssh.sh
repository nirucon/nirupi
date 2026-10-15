#!/usr/bin/env bash
# NIRU SSH/host picker: pick a host (from ~/.ssh/config and Tailscale peers)
# and open a shell in a terminal.
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI SSH "$1" >/dev/null 2>&1 || :; }

hosts(){
  {
    awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i !~ /[*?!]/) print $i}' "$HOME/.ssh/config" 2>/dev/null || true
    if have tailscale; then
      tailscale status 2>/dev/null | awk 'NF>=2 && $1 !~ /^#/ {print $2}'
    fi
  } | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -vE '^$' \
    | grep -vx "$(hostname)" | grep -vx "$(hostname -s 2>/dev/null)" \
    | sort -u
}

list="$(hosts)"
[[ -n $list ]] || { note 'No hosts found (add some to ~/.ssh/config, or start Tailscale)'; exit 0; }

host="$(printf '%s\n' "$list" | { if have rofi; then rofi -dmenu -i -p 'SSH host'; elif have dmenu; then dmenu -i -p 'SSH host'; else cat; fi; } || true)"
[[ -n $host ]] || exit 0
host="${host%% *}"
[[ -n $host ]] || exit 0

if [[ -t 0 && -t 1 ]]; then exec ssh -t "$host"; fi
for t in kitty alacritty st xterm; do
  have "$t" && exec "$t" -e ssh -t "$host"
done
note "Open a terminal and run:  ssh $host"
