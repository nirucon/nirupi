#!/usr/bin/env bash
# NIRU wallpaper helper.
#   nirupi-wallpaper.sh set FILE     set one image on every output (instant)
#   nirupi-wallpaper.sh next         random image from the pool
#   nirupi-wallpaper.sh tag          per-workspace image (dwm tag hook)
#   nirupi-wallpaper.sh per-tag on|off|toggle|status
# Config: ~/.config/nirupi/wallpapers.conf
#   PER_TAG=1            per-workspace wallpapers on/off
#   DEFAULT_DIR=...      random pool for tags without an explicit image
#   N=/path              explicit image for tag N
# Switching is instant (feh/xwallpaper/hsetroot) — no compositor, no stutter.
set -Eeuo pipefail

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/wallpapers.conf"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/dwm-status/current-wallpaper"
LOCK="$CACHE/tag-wallpaper.lock"
mkdir -p "$CACHE" "$(dirname "$STATE")"

log(){ printf '[wallpaper] %s\n' "$*" >&2; }
note(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI Wallpaper "$*" >/dev/null 2>&1 || :; }

conf_get(){
  local key="$1"
  [[ -f $CONF ]] || return 0
  sed -n "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//p" "$CONF" | tail -n1 \
    | sed -e 's/^"//' -e 's/"[[:space:]]*$//' | sed -e "s#\\\$HOME#$HOME#g" -e "s#^~#$HOME#"
}
conf_set(){
  local key="$1" val="$2" tmp
  mkdir -p "$(dirname "$CONF")"; [[ -f $CONF ]] || : > "$CONF"
  tmp="$(mktemp "$(dirname "$CONF")/.wallconf.XXXXXXXX")"
  awk -v k="$key" -v v="$val" '
    BEGIN{done=0}
    $0 ~ "^[[:space:]]*"k"[[:space:]]*=" { if(!done){print k"=\""v"\""; done=1}; next }
    {print}
    END{ if(!done) print k"=\""v"\"" }' "$CONF" > "$tmp"
  mv -f -- "$tmp" "$CONF"
}
per_tag_on(){ [[ "$(conf_get PER_TAG)" == 0 ]] && return 1; return 0; }

# Wallpaper pools live as subdirectories of the Nextcloud wallpaper folder.
# NOIR is the default; every other subdirectory is offered too. Files directly
# in the parent are never used.
NC_ROOT="$HOME/Nextcloud/Wallpapers"
POOL_DIR(){ # NAME -> path, or empty
  local n="$1"
  [[ -n $n ]] || return 1
  [[ -d "$NC_ROOT/$n" ]] && { printf '%s' "$NC_ROOT/$n"; return 0; }
  [[ -d $n ]] && { printf '%s' "$n"; return 0; }   # absolute/loose path
  return 1
}
pool_names(){
  [[ -d $NC_ROOT ]] || return 0
  find "$NC_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}
# default_dir: the configured pool, falling back to ~/Pictures/Wallpapers when
# Nextcloud is absent (algiz) or not mounted, so nothing regresses.
default_dir(){
  local d; d="$(conf_get DEFAULT_DIR)"
  if [[ -n $d && -d $d ]]; then printf '%s' "$d"; return 0; fi
  if [[ -n $d && $d == "$NC_ROOT"/* && -d "$HOME/Pictures/Wallpapers" ]]; then
    printf '%s' "$HOME/Pictures/Wallpapers"; return 0
  fi
  printf '%s' "${d:-$HOME/Pictures/Wallpapers}"
}

images_in(){
  find -L "$1" -maxdepth 2 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
    2>/dev/null
}

set_once(){ # FILE — apply to every output (fast, single call)
  local f="$1" n i; [[ -f $f ]] || return 1
  if command -v xwallpaper >/dev/null 2>&1; then
    xwallpaper --zoom "$f" && return 0
  fi
  if command -v feh >/dev/null 2>&1; then
    n="$(xrandr --listactivemonitors 2>/dev/null | awk 'NR>1' | wc -l)"
    if [[ ${n:-0} -gt 1 ]]; then
      local args=(); for ((i=0;i<n;i++)); do args+=("$f"); done
      feh --no-fehbg --bg-fill "${args[@]}" && return 0
    fi
    feh --no-fehbg --bg-fill "$f" && return 0
  fi
  if command -v hsetroot >/dev/null 2>&1; then hsetroot -cover "$f" && return 0; fi
  return 1
}

apply(){ # FILE
  local f="$1"
  [[ -f $f ]] || { log "not a file: $f"; return 1; }
  set_once "$f" || true
  printf '%s\n' "$f" > "$STATE" 2>/dev/null || true
}

tag_index(){ # bitmask -> 1-based highest-priority tag
  local m="$1" i
  for ((i=0;i<32;i++)); do (( m & (1<<i) )) && { printf '%d' $((i+1)); return; }; done
  printf '1'
}

tag_image(){ # TAGNUM -> path (explicit mapping, else cached random from pool)
  local t="$1" explicit cached dir pool
  explicit="$(conf_get "$t")"
  if [[ -n $explicit && -f $explicit ]]; then printf '%s' "$explicit"; return 0; fi
  cached="$CACHE/tag-wallpaper.$t"
  if [[ -s $cached && -f "$(cat "$cached")" ]]; then cat "$cached"; return 0; fi
  dir="$(default_dir)"; [[ -d $dir ]] || return 1
  pool="$(images_in "$dir")"; [[ -n $pool ]] || return 1
  local pick; pick="$(printf '%s\n' "$pool" | shuf -n1 2>/dev/null || printf '%s\n' "$pool" | head -n1)"
  printf '%s' "$pick" > "$cached" 2>/dev/null || true
  printf '%s' "$pick"
}

cmd_tag(){
  per_tag_on || return 0
  [[ -n ${DISPLAY:-} ]] || return 0
  local tset="${NIRUPI_TAGSET:-1}" t img
  t="$(tag_index "$tset")"
  img="$(tag_image "$t")" || return 0
  # Serialise overlapping switches so the last one wins cleanly.
  exec 9>"$LOCK" 2>/dev/null || true
  if command -v flock >/dev/null 2>&1; then flock -w 5 9 2>/dev/null || true; fi
  apply "$img"
}

cmd_next(){
  local dir img; dir="$(default_dir)"
  img="$(images_in "$dir" | shuf -n1 2>/dev/null || true)"
  [[ -n $img ]] || { log "no images in $dir"; return 1; }
  rm -f -- "$CACHE"/tag-wallpaper.* 2>/dev/null || true
  apply "$img"
}

cmd_pool(){
  local want="${1:-}" name dir
  case "$want" in
    ''|-h|--help|help)
      printf 'Wallpaper pool: %s\n' "$(default_dir)"
      printf 'Available pools (subdirectories of %s):\n' "$NC_ROOT"
      local n
      while IFS= read -r n; do
        [[ -n $n ]] || continue
        [[ "$(default_dir)" == "$NC_ROOT/$n" ]] && printf '  %-18s %s (active)\n' "$n" "$NC_ROOT/$n" \
          || printf '  %-18s %s\n' "$n" "$NC_ROOT/$n"
      done < <(pool_names)
      [[ -n "$(pool_names)" ]] || printf '  (no Nextcloud wallpaper folders found)\n'
      printf '\nUse: nirupi wallpaper pool NAME   (or a full path; "default" = NOIR)\n'
      return 0;;
    default|noir|NOIR) name=NOIR;;
    *) name="$want";;
  esac
  dir="$(POOL_DIR "$name")" || { log "no such pool: $name"; return 1; }
  conf_set DEFAULT_DIR "$dir"
  rm -f -- "$CACHE"/tag-wallpaper.* 2>/dev/null || true
  note "Wallpaper pool: ${dir##*/}"
  printf '%s\n' "$dir"
  # Repaint the current tag right away.
  [[ -n ${DISPLAY:-} ]] && cmd_tag || true
}

usage(){ cat <<EOF
Usage: nirupi wallpaper set FILE
       nirupi wallpaper next
       nirupi wallpaper pool [NAME]     show or switch the wallpaper folder
       nirupi wallpaper per-tag on|off|toggle|status
       nirupi wallpaper tag         (internal: dwm tag hook)
Config: $CONF
EOF
}

sub="${1:-}"; shift || :
case "$sub" in
  set)      [[ $# -ge 1 ]] || { usage; exit 2; }; apply "$1";;
  next|random) cmd_next;;
  pool|dir) cmd_pool "${1:-}";;
  tag)      cmd_tag;;
  per-tag)
    case "${1:-status}" in
      on)  conf_set PER_TAG 1; note "Per-workspace wallpapers: on";;
      off) conf_set PER_TAG 0; note "Per-workspace wallpapers: off";;
      toggle) per_tag_on && conf_set PER_TAG 0 || conf_set PER_TAG 1;
              per_tag_on && note "Per-workspace wallpapers: on" || note "Per-workspace wallpapers: off";;
      status) if per_tag_on; then echo 'on'; else echo 'off'; fi;;
      *) usage; exit 2;;
    esac;;
  ''|-h|--help|help) usage;;
  *) usage; exit 2;;
esac
