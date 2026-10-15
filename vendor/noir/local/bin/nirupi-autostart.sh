#!/usr/bin/env bash
# NIRU autostart.
# Runs ~/.config/nirupi/autostart/*.sh at login, optionally on a chosen
# workspace (tag 1-9). Each file is a small shell script whose leading comments
# carry directives:
#
#   # name: Agent            (label for `nirupi autostart list`)
#   # tag: 2                 (open on workspace 2; omit to use the current one)
#   # settle: 3              (seconds to wait after launching on that tag)
#   # enabled: false         (skip without deleting the file)
#   exec kitty -e opencode
#
# Desktop app: put the command directly, e.g. `exec helium-browser`.
# TUI app:     wrap it in a terminal, e.g. `exec kitty -e btop`.
#
#   nirupi autostart list
#   nirupi autostart run
#   nirupi autostart path
set -Eeuo pipefail
DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/autostart"
have(){ command -v "$1" >/dev/null 2>&1; }

directive(){ # FILE KEY -> value (from a `# key: value` comment)
  sed -n "s/^[[:space:]]*#[[:space:]]*$2[[:space:]]*[:=][[:space:]]*//p" "$1" 2>/dev/null | tail -n1 | tr -d '"'
}
entries(){ [[ -d $DIR ]] && find "$DIR" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort; }
disabled(){ case "$1" in false|0|no|off) return 0;; *) return 1;; esac; }
viewtag(){ have xdotool || return 1; xdotool key --clearmodifiers "super+$1" >/dev/null 2>&1; }

run(){
  [[ -d $DIR ]] || return 0
  local f tag settle lasttag=""
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    disabled "$(directive "$f" enabled)" && continue
    tag="$(directive "$f" tag)"; [[ -n $tag ]] || tag="$(directive "$f" workspace)"
    settle="$(directive "$f" settle)"; [[ $settle =~ ^[0-9]+$ ]] || settle="${NIRUPI_AUTOSTART_SETTLE:-2}"
    if [[ $tag =~ ^[1-9]$ ]] && [[ $lasttag != "$tag" ]]; then
      viewtag "$tag" && lasttag="$tag" || true
    fi
    ( bash "$f" >/dev/null 2>&1 & ) || true
    [[ -n $tag ]] && sleep "$settle"
  done < <(entries)
  [[ -n $lasttag ]] && { viewtag 1 || true; }
  return 0
}

list(){
  printf 'Autostart dir: %s\n' "$DIR"
  [[ -d $DIR ]] || { printf '  (does not exist yet; create it and drop *.sh files in)\n'; return 0; }
  local f name tag enabled any=0
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    any=1
    name="$(directive "$f" name)"; [[ -n $name ]] || name="$(basename "$f")"
    tag="$(directive "$f" tag)"; [[ -n $tag ]] || tag="$(directive "$f" workspace)"
    enabled="$(directive "$f" enabled)"
    if disabled "$enabled"; then state=disabled; else state=enabled; fi
    printf '  %-26s tag=%-3s %s\n' "$name" "${tag:--}" "$state"
  done < <(entries)
  (( any )) || printf '  (no *.sh entries)\n'
}

case "${1:-run}" in
  run) run;;
  list|status) list;;
  path) printf '%s\n' "$DIR";;
  ''|-h|--help|help) printf 'Usage: nirupi autostart [list|run|path]\n';;
  *) printf 'Usage: nirupi autostart [list|run|path]\n' >&2; exit 2;;
esac
