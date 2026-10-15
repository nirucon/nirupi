#!/usr/bin/env bash
# Status-bar pop-up: network panel. Shows the active connection's details with
# a clean framed panel (uses nmcli when present, ip(8) otherwise) — no menu.
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
nm(){ have nmcli && nmcli -t -f "$1" "$2" 2>/dev/null || true; }

dev=""; type=""; state=""
if have nmcli; then
  dev="$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$3=="connected"{print $1; exit}')"
  [[ -n $dev ]] && { type="$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: -v d="$dev" '$1==d{print $2; exit}')"; state="connected"; }
fi
if [[ -z $dev ]] && have ip; then
  dev="$(ip -brief addr show 2>/dev/null | awk '$1!="lo"{print $1; exit}')"
  case "$dev" in wl*|wlp*|wlan*) type=wifi;; *) type=ethernet;; esac
  [[ -n $dev ]] && state=connected
fi
[[ -n $dev ]] || { printf '@title Network\n@sub offline\n@note No active connection.\n' | NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Network >/dev/null 2>&1; exit 0; }

if type=wifi; then
  conn="$(nmcli -t -f GENERAL.CONNECTION device show "$dev" 2>/dev/null | awk -F: '{print $2}' | head -1)"
  sig="$(nmcli -t -f IN-USE,SIGNAL device wifi list 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')"
  [[ -z ${conn:-} ]] && conn="$(ip -brief addr show "$dev" 2>/dev/null | awk '{print $1}')"
fi
if [[ $type == ethernet ]]; then
  conn="$(nmcli -t -f GENERAL.CONNECTION device show "$dev" 2>/dev/null | awk -F: '{print $2}' | head -1)"
  [[ -z ${conn:-} ]] && conn="Wired connection"
fi

ip4="$(ip -4 -brief addr show "$dev" 2>/dev/null | awk '{print $3}')"
ip6="$(ip -6 -brief addr show "$dev" 2>/dev/null | awk '$3 !~ /^fe80/{print $3}' | head -1)"
gw="$(ip route show default dev "$dev" 2>/dev/null | awk '{print $3; exit}')"
dns="$( { nmcli -t -f IP4.DNS device show "$dev" 2>/dev/null | awk -F: '{print $2}'; grep -h '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}'; } | awk 'NF && !seen[$0]++' | head -3 | paste -sd ' ' -)"
mac="$(ip link show "$dev" 2>/dev/null | awk '/link\/(ether|ieee80211)/{print $2; exit}')"
speed=""
if [[ $type == ethernet ]] && have ethtool; then
  sp="$(ethtool "$dev" 2>/dev/null | awk -F': ' '/Speed/{print $2; exit}')"
  [[ -n $sp && $sp != Unknown* ]] && speed="$sp"
fi
rx="$(cat "/sys/class/net/$dev/statistics/rx_bytes" 2>/dev/null)"
tx="$(cat "/sys/class/net/$dev/statistics/tx_bytes" 2>/dev/null)"
hum(){ [[ ${1:-} =~ ^[0-9]+$ ]] && awk -v b="$1" 'BEGIN{s="B KiB MiB GiB TiB"; i=0; while(b>=1024&&i<4){b/=1024;i++} printf "%.1f %s", b, substr(s, i*4+1, 3+ (i==0))}' || true; }

accent=cyan; [[ $type == ethernet ]] && accent=green
{
  printf '@title Network\n'
  printf '@sub %s — %s\n' "$dev" "$type"
  printf '@accent %s\n' "$accent"
  [[ $type == wifi && -n ${sig:-} ]] && { printf '@bar %s\n' "$sig"; printf '@row Signal|%s%%\n' "$sig"; }
  [[ -n ${conn:-} ]] && printf '@row Network|%s\n' "$conn"
  [[ -n ${speed:-} ]] && printf '@row Speed|%s\n' "$speed"
  [[ -n ${ip4:-} ]] && printf '@row IPv4|%s\n' "$ip4"
  [[ -n ${gw:-} ]] && printf '@row Gateway|%s\n' "$gw"
  [[ -n ${dns:-} ]] && printf '@row DNS|%s\n' "$dns"
  [[ -n ${ip6:-} ]] && printf '@row IPv6|%s\n' "$ip6"
  [[ -n ${mac:-} ]] && printf '@row MAC|%s\n' "$mac"
  [[ -n ${rx:-} ]] && printf '@note Received %s · Sent %s\n' "$(hum "$rx")" "$(hum "$tx")"
  if have tailscale && tailscale status >/dev/null 2>&1; then
    ts="$(tailscale ip -4 2>/dev/null | head -1)"
    [[ -n $ts ]] && printf '@note Tailscale up (%s)\n' "$ts"
  fi
} | NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Network >/dev/null 2>&1 || true
