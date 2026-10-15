#!/usr/bin/env bash
# Status-bar pop-up: weather forecast via Open-Meteo (the same source as the
# bar). The first line lets you change the location by name (geocoded).
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"
conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/status.conf"
[[ -r $conf ]] && . "$conf"
NAME="${WEATHER_NAME:-Ljungskile}"
lat="${WEATHER_LAT:-58.2245}"; lon="${WEATHER_LON:-11.9201}"; tz="${WEATHER_TIMEZONE:-Europe/Stockholm}"
PO="$HOME/.local/bin/nirupi-popup.sh"
have(){ command -v "$1" >/dev/null 2>&1; }
have jq || { printf 'jq is required\n' | "$PO" 'Weather' >/dev/null 2>&1; exit 0; }

wcode(){ case "${1:-}" in
  0) echo clear;; 1) echo "mostly clear";; 2) echo "partly cloudy";; 3) echo overcast;;
  45|48) echo fog;; 51|53|55) echo drizzle;; 56|57) echo "freezing drizzle";;
  61|63|65) echo rain;; 66|67) echo "freezing rain";; 71|73|75|77) echo snow;;
  80|81|82) echo showers;; 85|86) echo "snow showers";; 95) echo thunderstorm;;
  96|99) echo "thunderstorm, hail";; *) echo "code ${1:-?}";; esac; }

set_conf(){
  # set_conf KEY VALUE ... : update keys in status.conf (create if missing).
  mkdir -p "$(dirname "$conf")"; touch "$conf"
  local k v tmp; tmp="$(mktemp)"
  cp -- "$conf" "$tmp"
  while (( $# >= 2 )); do
    k="$1"; v="$2"; shift 2
    if grep -q "^${k}=" "$tmp"; then
      sed -i "s|^${k}=.*|${k}=${v}|" "$tmp"
    else
      printf '%s=%s\n' "$k" "$v" >> "$tmp"
    fi
  done
  mv -f -- "$tmp" "$conf"
}

forecast(){
  local url="https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=${tz//\//%2F}&forecast_days=4"
  curl -fsS --max-time 8 "$url" 2>/dev/null
}

show(){
  local j="$1" nowh idx
  nowh="$(date +%Y-%m-%dT%H:00)"
  idx="$(printf '%s' "$j" | jq --arg n "$nowh" '[.hourly.time[] | . == $n] | index(true) // 0')"
  printf '▸ Change location…          (%s)\n' "$NAME"
  local t w
  t="$(printf '%s' "$j" | jq -r '.current.temperature_2m')"
  w="$(printf '%s' "$j" | jq -r '.current.weather_code')"
  printf 'Now: %s°C  %s\n' "$t" "$(wcode "$w")"
  printf -- '──────── hours ────────\n'
  printf '%s' "$j" | jq -r --argjson i "$idx" \
    '.hourly as $h | range($i; [$i+8, ($h.time|length)]|min) | "\($h.time[.][5:16]|sub("T";" "))   \($h.temperature_2m[.])°C   \($h.weather_code[.])"' \
    | while IFS=$'\t' read -r time temp code; do printf '%s   %s   %s\n' "$time" "$temp" "$(wcode "$code")"; done
  printf -- '──────── days ────────\n'
  printf '%s' "$j" | jq -r '.daily as $d | range(0; ($d.time|length)) | "\($d.time[.])   \($d.temperature_2m_min[.])–\($d.temperature_2m_max[.])°C   \($d.weather_code[.])"' \
    | while IFS=$'\t' read -r day rng code; do printf '%s   %s   %s\n' "$day" "$rng" "$(wcode "$code")"; done
}

change(){
  have rofi || return 0
  local q name nlat nlon geo
  q="$(rofi -dmenu -i -p 'Town (e.g. Ljungskile)' </dev/null)" || return 0
  [[ -n ${q// /} ]] || return 0
  geo="$(curl -fsS --max-time 8 "https://geocoding-api.open-meteo.com/v1/search?name=$(printf '%s' "$q" | sed 's/ /%20/g')&count=1&language=sv&format=json" 2>/dev/null || true)"
  nlat="$(printf '%s' "$geo" | jq -r '.results[0].latitude // empty' 2>/dev/null)"
  nlon="$(printf '%s' "$geo" | jq -r '.results[0].longitude // empty' 2>/dev/null)"
  name="$(printf '%s' "$geo" | jq -r '.results[0].name // empty' 2>/dev/null)"
  [[ -n $nlat && -n $nlon ]] || { printf 'Location not found: %s\n' "$q" | "$PO" 'Weather' >/dev/null 2>&1; return 0; }
  set_conf WEATHER_NAME "$name" WEATHER_LAT "$nlat" WEATHER_LON "$nlon"
  NAME="$name"; lat="$nlat"; lon="$nlon"
}

j="$(forecast)"
if [[ -z $j ]]; then
  sel="$(printf 'Could not fetch the forecast (offline?)\n▸ Change location…\n' | "$PO" 'Weather' 2>/dev/null || true)"
  [[ $sel == *'Change location'* ]] && change
  exit 0
fi
sel="$(show "$j" | "$PO" 'Weather ☀' 2>/dev/null || true)"
if [[ $sel == *'Change location'* ]]; then change; fi
