#!/usr/bin/env bash
# NIRU SSH/host picker: pick a host (from ~/.ssh/config and Tailscale peers)
# and open a shell in a terminal.
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI SSH "$1" >/dev/null 2>&1 || :; }

hosts(){
  local self short raw
  # `hostname` is not in a vanilla Arch base; use /etc/hostname/uname instead.
  self="$(cat /etc/hostname 2>/dev/null || uname -n 2>/dev/null)"
  short="${self%%.*}"
  raw="$(
    awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i !~ /[*?!]/) print $i}' "$HOME/.ssh/config" 2>/dev/null || true
    if have tailscale; then
      tailscale status 2>/dev/null | awk 'NF>=2 && $1 !~ /^#/ {print $2}'
    fi
  )" || true
  printf '%s\n' "$raw" \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | awk -v s="$self" -v sh="$short" 'NF && $1!=s && $1!=sh && !seen[$1]++ {print $1}'
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
