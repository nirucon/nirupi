#!/usr/bin/env bash
# Status-bar pop-up: Wi-Fi picker (rofi/dmenu). The connected network is listed
# first and marked; the rest are sorted by signal with strength bars. Selecting
# the current one offers info/disconnect; selecting another connects (asking for
# a password only when the connection needs one).
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ if have notify-send; then notify-send -a NIRUPI "Wi-Fi" "$1"; else printf 'Wi-Fi: %s\n' "$1"; fi; }
pick(){ if have rofi; then rofi -dmenu -i -p 'Wi-Fi'; elif have dmenu; then dmenu -i -p 'Wi-Fi'; else head -n1; fi; }

have nmcli || { notify 'NetworkManager (nmcli) not available'; exit 0; }

bars(){ local s="${1:-0}"; if (( s>=75 )); then printf '▂▄▆█'; elif (( s>=50 )); then printf '▂▄▆_'; elif (( s>=25 )); then printf '▂▄__'; else printf '▂___'; fi; }
active="$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')"

rows=()
declare -A seen=()
# Parse once, keep the strongest BSSID per SSID, connected first, then signal.
mapfile -t nets < <(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null)
for line in "${nets[@]}"; do
  IFS=: read -r inuse ssid signal sec <<<"$line"
  [[ -n $ssid ]] || continue
  key="$ssid"
  if [[ -n ${seen[$key]:-} ]]; then
    # keep the stronger signal (and prefer the in-use entry)
    prev_sig="${seen[$key]%%|*}"; prev_in="${seen[$key]#*|}"
    if [[ $inuse == "*" && $prev_in != "*" ]] || { [[ $inuse == "$prev_in" ]] && (( ${signal:-0} > ${prev_sig:-0} )); }; then
      seen[$key]="$signal|$inuse|$sec"
    fi
  else
    seen[$key]="$signal|$inuse|$sec"
  fi
done
# emit: connected first, then by descending signal
for ssid in "${!seen[@]}"; do
  IFS='|' read -r signal inuse sec <<<"${seen[$ssid]}"
  printf '%s\t%s\t%s\t%s\n' "$([[ $inuse == "*" ]] && echo 1 || echo 0)" "$signal" "$ssid" "$sec"
done | sort -t$'\t' -k1,1nr -k2,2nr | while IFS=$'\t' read -r isconn signal ssid sec; do
  lock=""; [[ -n $sec && $sec != -- ]] && lock="🔒"
  if [[ $isconn == 1 ]]; then
    active="$ssid"
    rows+=("● $ssid  $(bars "$signal") ${signal}%  connected  $lock")
  else
    rows+=("  $ssid  $(bars "$signal") ${signal}%  $lock")
  fi
done

if (( ${#rows[@]} == 0 )); then
  scan="$(nmcli -t -f SSID device wifi rescan 2>/dev/null; true)"
  sleep 1
  while IFS=: read -r inuse ssid signal sec; do
    [[ -n $ssid && $ssid != "$active" ]] || continue
    rows+=("  $ssid  $(bars "$signal") ${signal}%  $([[ -n $sec && $sec != -- ]] && echo 🔒)")
  done < <(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | sort -t: -k3 -rn)
fi
[[ ${#rows[@]} -gt 0 ]] || { notify 'No networks found'; exit 0; }
[[ -n $active ]] && rows+=("✕ Disconnect (${active})")

sel="$(printf '%s\n' "${rows[@]}" | pick)" || exit 0
[[ -n $sel ]] || exit 0

case "$sel" in
  '✕ Disconnect'*)
    nmcli device disconnect "$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')" >/dev/null 2>&1 \
      && notify 'Disconnected' || notify 'Could not disconnect'; exit 0;;
esac

ssid="${sel#* }"; ssid="${ssid%%  *}"   # strip the leading marker + trailing bars
ssid="$(printf '%s' "$ssid" | sed 's/[[:space:]]*$//')"

if [[ $ssid == "$active" ]]; then
  ip="$(ip -4 -brief addr show "$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')" 2>/dev/null | awk '{print $3}')"
  notify "Connected to $ssid${ip:+ — $ip}"; exit 0
fi

# Connect. NetworkManager asks for secrets itself when required (--ask); we only
# fall back to an explicit password prompt if that fails.
if nmcli --ask device wifi connect "$ssid" 2>/tmp/nmcli.err; then
  notify "Connected to $ssid"
else
  err="$(tr '\n' ' ' </tmp/nmcli.err)"
  if grep -qiE 'secrets|password|802-11' /tmp/nmcli.err; then
    pw=""
    if have rofi; then pw="$(rofi -dmenu -password -p "Password for $ssid" </dev/null)"; fi
    [[ -n $pw ]] || { notify 'Cancelled'; exit 0; }
    nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1 \
      && notify "Connected to $ssid" || notify "Could not connect to $ssid"
  else
    notify "Failed: ${err:-unknown error}"
  fi
fi
