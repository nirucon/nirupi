#!/usr/bin/env bash
# Status-bar pop-up: battery details (charge, status, health, power, estimate).
set -Eeuo pipefail
bat="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)"
if [[ -z ${bat:-} ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "Battery" "No battery (desktop)" || printf 'No battery\n'
  exit 0
fi
rd(){ cat "$1" 2>/dev/null; }
cap="$(rd "$bat/capacity")"
st="$(rd "$bat/status")"
full="$(rd "$bat/energy_full")"; design="$(rd "$bat/energy_full_design")"
now="$(rd "$bat/power_now")"
volt="$(rd "$bat/voltage_now")"
health=""
if [[ ${full:-0} =~ ^[0-9]+$ && ${design:-0} =~ ^[0-9]+$ && "$design" -gt 0 ]]; then
  health="$(( full * 100 / design ))% of design"
fi
watts=""
[[ ${now:-0} =~ ^[0-9]+$ && "$now" -gt 0 ]] && watts="$(awk -v p="$now" 'BEGIN{printf "%.1f", p/1e6}') W"
est=""
if [[ ${now:-0} =~ ^[0-9]+$ && "$now" -gt 0 && $st == Discharging ]]; then
  est="$(awk -v e="$full" -v p="$now" -v c="$cap" 'BEGIN{ if(p>0) printf "%d min", (e*(c/100))/p*60 }')"
fi
{
  printf 'Charge: %s%%\n' "${cap:-?}"
  printf 'Status: %s\n' "${st:-?}"
  [[ -n $health ]] && printf 'Health: %s\n' "$health"
  [[ -n $watts ]] && printf 'Power: %s\n' "$watts"
  [[ -n $est ]] && printf 'Remaining: %s\n' "$est"
  [[ -n ${volt:-} ]] && [[ $volt =~ ^[0-9]+$ ]] && printf 'Voltage: %s V\n' "$(awk -v v="$volt" 'BEGIN{printf "%.2f", v/1e6}')"
} | "$HOME/.local/bin/nirupi-popup.sh" 'Battery' >/dev/null 2>&1 || true
