#!/usr/bin/env bash
# NIRUPI missions — open a named set of apps on their workspaces.
#
#   nirupi mission                 pick a mission (rofi/dmenu)
#   nirupi mission NAME            run it
#   nirupi mission --list          list missions
#   nirupi mission --edit          edit ~/.config/nirupi/missions.conf
#
# Format: name|tag|command
#   work|1|helium
#   work|6|kitty
#   work|2|opencode
set -Eeuo pipefail

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/missions.conf"
have(){ command -v "$1" >/dev/null 2>&1; }

ensure_conf(){
 [[ -f $CONF ]] && return 0
 [[ -L $CONF ]] && return 1
 mkdir -p "$(dirname "$CONF")"
 cat > "$CONF" <<'EOC'
# NIRUPI missions: name|tag|command
# A tag of 0 keeps the current workspace. Commands run detached.
work|1|helium
work|6|kitty
work|2|opencode
music|9|helium https://music.youtube.com
EOC
}
ensure_conf || true

names(){
 awk -F'|' '/^[[:space:]]*[^#]/ && NF>=3 {gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1); print $1}' "$CONF" | awk '!seen[$0]++'
}

list_missions(){
 printf '%-16s %s\n' 'MISSION' 'APPS'
 local n
 while IFS= read -r n; do
  [[ -n $n ]] || continue
  printf '%-16s ' "$n"
  awk -F'|' -v n="$n" '/^[[:space:]]*[^#]/ {gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1); if($1==n) printf "%s ", $2}' "$CONF"
  printf '\n'
 done < <(names)
 return 0
}

pick(){
 local sel
 if have rofi; then sel="$(names | rofi -dmenu -i -p 'Mission')"
 elif have dmenu; then sel="$(names | dmenu -i -p 'Mission')"
 else names; fi
 printf '%s' "${sel:-}"
}

run_mission(){
 local name="$1" tag cmd
 [[ -n $name ]] || exit 0
 awk -F'|' -v n="$name" '
  /^[[:space:]]*[^#]/ && NF>=3 {
   gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1);
   if ($1==n) { gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2 "|" $3 }
  }' "$CONF" | while IFS='|' read -r tag cmd; do
   [[ -n $cmd ]] || continue
   if [[ $tag =~ ^[1-9]$ ]] && have xdotool; then
    xdotool key --clearmodifiers "super+$tag" >/dev/null 2>&1 || :
    sleep 0.15
   fi
   setsid /bin/sh -c "$cmd" >/dev/null 2>&1 &
  done
 printf 'Mission: %s\n' "$name"
}

case "${1:-}" in
 --list|list) list_missions;;
 --edit|edit) exec "${EDITOR:-vi}" "$CONF";;
 -h|--help) sed -n '1,16p' "$0";;
 '') name="$(pick)"; run_mission "$name";;
 *) run_mission "$1";;
esac
