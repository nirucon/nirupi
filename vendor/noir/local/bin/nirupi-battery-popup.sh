#!/usr/bin/env bash
# Status-bar pop-up: battery details (charge, status, health, power, estimate).
# Robust: some drivers expose charge_full/charge_full_design instead of energy_*,
# and power_now may be missing — a missing attribute must never abort the pop-up.
set -Eeuo pipefail
rd(){ cat "$1" 2>/dev/null || true; }
bat="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)"
if [[ -z ${bat:-} ]]; then
  if command -v notify-send >/dev/null 2>&1; then notify-send -a NIRUPI "Battery" "No battery (desktop)"; else printf 'No battery\n'; fi
  exit 0
fi
cap="$(rd "$bat/capacity")"
st="$(rd "$bat/status")"
full="$(rd "$bat/energy_full")";        [[ -n $full ]]   || full="$(rd "$bat/charge_full")"
design="$(rd "$bat/energy_full_design")"; [[ -n $design ]] || design="$(rd "$bat/charge_full_design")"
now="$(rd "$bat/power_now")"
volt="$(rd "$bat/voltage_now")"

health=""
if [[ ${full:-} =~ ^[0-9]+$ && ${design:-} =~ ^[0-9]+$ && $design -gt 0 ]]; then
  health="$(( full * 100 / design ))% of design"
fi
watts=""
if [[ ${now:-} =~ ^[0-9]+$ && $now -gt 0 ]]; then
  watts="$(awk -v p="$now" 'BEGIN{printf "%.1f", p/1e6}') W"
fi
est=""
if [[ ${now:-} =~ ^[0-9]+$ && $now -gt 0 && ${full:-} =~ ^[0-9]+$ && ${cap:-} =~ ^[0-9]+$ && $st == Discharging ]]; then
  est="$(awk -v e="$full" -v p="$now" -v c="$cap" 'BEGIN{ if(p>0) printf "%d min", (e*(c/100))/p*60 }')"
fi
{
  printf 'Charge: %s%%\n' "${cap:-?}"
  printf 'Status: %s\n' "${st:-?}"
  [[ -n $health ]] && printf 'Health: %s\n' "$health"
  [[ -n $watts ]] && printf 'Power: %s\n' "$watts"
  [[ -n $est ]] && printf 'Remaining: %s\n' "$est"
  if [[ ${volt:-} =~ ^[0-9]+$ ]]; then printf 'Voltage: %s V\n' "$(awk -v v="$volt" 'BEGIN{printf "%.2f", v/1e6}')"; fi
} | "$HOME/.local/bin/nirupi-popup.sh" 'Battery' >/dev/null 2>&1 || true
