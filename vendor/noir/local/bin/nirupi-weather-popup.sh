#!/usr/bin/env bash
# Status-bar pop-up: SMHI forecast (temperature + condition) for a few hours.
# Location override: WEATHER_LAT / WEATHER_LON in ~/.config/nirupi/status.conf.
set -Eeuo pipefail
conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/status.conf"
[[ -r $conf ]] && . "$conf"
lat="${WEATHER_LAT:-58.2167}"; lon="${WEATHER_LON:-11.9333}"
command -v jq >/dev/null 2>&1 || { printf 'jq is required\n' | "$HOME/.local/bin/nirupi-popup.sh" 'Weather' >/dev/null 2>&1; exit 0; }
url="https://opendata-download-metfcst.smhi.se/api/category/pncgeccos/version/1/geopoint/lat/${lat}/lon/${lon}/data.json"
json="$(curl -fsS --max-time 8 "$url" 2>/dev/null || true)"
if [[ -z $json ]]; then
  printf 'Could not fetch the forecast (offline?)\n' | "$HOME/.local/bin/nirupi-popup.sh" 'Weather' >/dev/null 2>&1
  exit 0
fi
printf '%s' "$json" | jq -r '
  def sym($c):
    if   $c==1 then "clear" elif $c==2 then "mostly clear" elif ($c>=3 and $c<=4) then "partly cloudy"
    elif ($c>=5 and $c<=7) then "cloudy" elif ($c==8 or $c>=10 and $c<=15) then "showers"
    elif ($c>=16 and $c<=17) then "rain" elif ($c>=18 and $c<=20) then "snow" elif ($c>=21 and $c<=24) then "sleet"
    elif ($c==25 or $c==26) then "heavy rain" elif ($c>=27 and $c<=28) then "heavy snow"
    elif ($c==29 or $c==30) then "thunder" else "code \($c)" end;
  .timeSeries[0:12][]
  | (.validTime) as $t
  | ([.parameters[]|select(.name=="t")][0].values[0]) as $temp
  | ([.parameters[]|select(.name=="Wsymb2")][0].values[0]) as $sym
  | "\($t[5:10]) \($t[11:16])   \($temp|tostring)°C   \(sym($sym))"
' 2>/dev/null | "$HOME/.local/bin/nirupi-popup.sh" 'Weather (SMHI)' >/dev/null 2>&1 || true
