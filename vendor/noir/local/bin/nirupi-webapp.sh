#!/usr/bin/env bash
# NIRUPI webapp manager — quiet, Helium-first app-mode shortcuts.
#   nirupi webapp add NAME URL [--browser MODE] [--separate] [--class CLASS]
#   nirupi webapp list
#   nirupi webapp remove NAME
# Creates ~/.local/share/applications/<id>.desktop (+ a ~/.local/bin/<id>
# launcher), so apps show up in dmenu/rofi/palette.
set -Eeuo pipefail

BROWSER_PREF=(helium helium-browser brave brave-browser chromium chromium-browser google-chrome-stable)
APPS_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"
PROFILE_ROOT="$HOME/.local/share/webapps"

fail(){ printf 'NIRUPI webapp: %s\n' "$*" >&2; exit 1; }

safe_id(){
  local raw="$1" id
  id="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')"
  [[ -n $id ]] || id="webapp"
  [[ $id =~ ^[a-z] ]] || id="x$id"
  printf '%s' "$id"
}

resolve_browser(){
  local mode="${1:-auto}" c
  case "$mode" in
    auto|'') for c in "${BROWSER_PREF[@]}"; do command -v "$c" >/dev/null 2>&1 && { printf '%s' "$c"; return; }; done;;
    *) command -v "$mode" >/dev/null 2>&1 && { printf '%s' "$mode"; return; };;
  esac
  printf ''
}

desktop_of(){ printf '%s/%s.desktop' "$APPS_DIR" "$(safe_id "$1")"; }
bin_of(){ printf '%s/%s' "$BIN_DIR" "$(safe_id "$1")"; }

refresh_db(){
  command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || :
}

add_app(){
  local name="" url="" browser="auto" separate=0 class=""
  while (($#)); do
    case "$1" in
      --browser) browser="${2:-auto}"; shift;;
      --separate) separate=1;;
      --class) class="${2:-}"; shift;;
      -*) fail "unknown option: $1";;
      *) if [[ -z $name ]]; then name="$1"; elif [[ -z $url ]]; then url="$1"; else fail "unexpected argument: $1"; fi;;
    esac
    shift
  done
  [[ -n $name && -n $url ]] || fail 'usage: nirupi webapp add NAME URL [--browser MODE] [--separate] [--class CLASS]'
  [[ $url =~ ^https?:// ]] || fail 'URL must start with http:// or https://'

  local id; id="$(safe_id "$name")"
  [[ -z $class ]] && class="WebApp-${id}"
  [[ $id != webapp || -n $name ]] || fail 'invalid name'

  local desktop bin; desktop="$(desktop_of "$name")"; bin="$(bin_of "$name")"
  [[ ! -L $desktop && ! -L $bin ]] || fail "refusing to replace symlink for $name"
  mkdir -p -- "$APPS_DIR" "$BIN_DIR"

  local resolved; resolved="$(resolve_browser "$browser")"
  [[ -n $resolved ]] || fail 'no supported browser found (install helium, brave or chromium)'

  cat > "$bin" <<EOF
#!/usr/bin/env bash
set -euo pipefail
BROWSER=\$(command -v ${resolved} || true)
[[ -n \$BROWSER ]] || exit 1
URL=$(printf '%q' "$url")
CLASS=$(printf '%q' "$class")
EOF
  if (( separate )); then
    local profile="$PROFILE_ROOT/$id"
    cat >> "$bin" <<EOF
exec "\$BROWSER" --class="\$CLASS" --app="\$URL" --user-data-dir=$(printf '%q' "$profile") --profile-directory=Default
EOF
  else
    cat >> "$bin" <<'EOF'
exec "$BROWSER" --class="$CLASS" --app="$URL"
EOF
  fi
  chmod 0755 "$bin"

  cat > "$desktop" <<EOF
[Desktop Entry]
Name=${name}
Comment=WebApp for ${url}
Exec=${bin}
Terminal=false
Type=Application
Icon=web-browser
Categories=Network;
StartupWMClass=${class}
StartupNotify=true
X-NIRUPI-WebApp=true
X-NIRUPI-URL=${url}
X-NIRUPI-Browser=${resolved}
EOF
  chmod 0644 "$desktop"
  refresh_db
  printf 'Added webapp: %s (%s)\n' "$name" "$resolved"
}

list_apps(){
  [[ -d $APPS_DIR ]] || { printf 'No webapps.\n'; return 0; }
  local f found=0 name url
  for f in "$APPS_DIR"/*.desktop; do
    [[ -f $f && ! -L $f ]] || continue
    grep -q '^X-NIRUPI-WebApp=true$' "$f" || continue
    name="$(sed -n 's/^Name=//p' "$f" | head -n1)"
    url="$(sed -n 's/^X-NIRUPI-URL=//p' "$f" | head -n1)"
    printf '%-24s %s\n' "$name" "$url"
    found=1
  done
  (( found )) || printf 'No webapps.\n'
}

remove_app(){
  local name="${1:-}"; [[ -n $name ]] || fail 'usage: nirupi webapp remove NAME'
  local desktop bin; desktop="$(desktop_of "$name")"; bin="$(bin_of "$name")"
  [[ -f $desktop && ! -L $desktop ]] || fail "no managed webapp named '$name'"
  grep -q '^X-NIRUPI-WebApp=true$' "$desktop" || fail "'$name' is not a NIRUPI-managed webapp"
  rm -f -- "$desktop"
  if [[ -f $bin && ! -L $bin ]] && grep -q 'NIRUPI webapp\|WebApp-' "$bin" 2>/dev/null; then rm -f -- "$bin"; fi
  refresh_db
  printf 'Removed webapp: %s\n' "$name"
}

usage(){ printf 'nirupi webapp {add NAME URL [--browser MODE] [--separate] [--class CLASS] | list | remove NAME}\n'; }

cmd="${1:-}"; shift || :
case "${cmd}" in
  add) add_app "$@";;
  list|ls) list_apps;;
  remove|rm) remove_app "$@";;
  ''|-h|--help|help) usage;;
  *) fail "unknown subcommand: $cmd";;
esac
