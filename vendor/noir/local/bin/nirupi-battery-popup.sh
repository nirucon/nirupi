#!/usr/bin/env bash
# Status-bar pop-up: battery panel (charge/status/health/power, with a bar).
set -Eeuo pipefail
rd(){ cat "$1" 2>/dev/null || true; }
bat="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)"
if [[ -z ${bat:-} ]]; then
  printf '@title Battery\n@sub Desktop\n@note No battery on this machine.\n' \
    | NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Battery >/dev/null 2>&1 || true
  exit 0
fi
cap="$(rd "$bat/capacity")"
st="$(rd "$bat/status")"
full="$(rd "$bat/energy_full")";        [[ -n $full ]]   || full="$(rd "$bat/charge_full")"
design="$(rd "$bat/energy_full_design")"; [[ -n $design ]] || design="$(rd "$bat/charge_full_design")"
now="$(rd "$bat/power_now")"
volt="$(rd "$bat/voltage_now")"
model="$(cat "$bat/../*/model_name" 2>/dev/null | head -n1 || true)"

health=""
[[ ${full:-} =~ ^[0-9]+$ && ${design:-} =~ ^[0-9]+$ && $design -gt 0 ]] && health="$(( full * 100 / design ))%"
watts=""; [[ ${now:-} =~ ^[0-9]+$ && $now -gt 0 ]] && watts="$(awk -v p="$now" 'BEGIN{printf "%.1f W", p/1e6}')"
est=""
[[ ${now:-} =~ ^[0-9]+$ && $now -gt 0 && ${full:-} =~ ^[0-9]+$ && ${cap:-} =~ ^[0-9]+$ && $st == Discharging ]] \
  && est="$(awk -v e="$full" -v p="$now" -v c="$cap" 'BEGIN{ if(p>0){m=(e*(c/100))/p*60; printf "%.0f h %02.0f m", m/60, m%60} }')"
volts=""; [[ ${volt:-} =~ ^[0-9]+$ ]] && volts="$(awk -v v="$volt" 'BEGIN{printf "%.2f V", v/1e6}')"

accent=green
[[ ${cap:-100} =~ ^[0-9]+$ ]] && { [[ ${cap} -le 20 ]] && accent=red; [[ ${cap} -gt 20 && ${cap} -le 40 ]] && accent=yellow; }

{
  printf '@title Battery\n'
  printf '@sub %s\n' "${model:-$(basename "$bat")}"
  printf '@accent %s\n' "$accent"
  printf '@bar %s\n' "${cap:-0}"
  printf '@row Charge|%s%%\n' "${cap:-?}"
  [[ -n $health ]] && printf '@row Health|%s\n' "$health"
  printf '@row Status|%s\n' "${st:-?}"
  [[ -n $watts ]] && printf '@row Power|%s\n' "$watts"
  [[ -n $volts ]] && printf '@row Voltage|%s\n' "$volts"
  if [[ -n $est ]]; then printf '@note About %s remaining.\n' "$est"
  elif [[ $st == Charging ]]; then printf '@note Charging.\n'
  elif [[ $st == Full ]]; then printf '@note Fully charged.\n'; fi
} | NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Battery >/dev/null 2>&1 || true
