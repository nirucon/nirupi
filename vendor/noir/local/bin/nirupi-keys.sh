#!/usr/bin/env bash
# NIRUPI keybinding cheat-sheet / command palette.
#   nirupi-keys.sh            rofi picker (falls back to fzf, then plain list)
#   nirupi-keys.sh --list     print the generated list
#   nirupi-keys.sh -c CAT     filter by category
# Source of truth: the installed dwm config.h, so the list never drifts.
set -Eeuo pipefail

CONFIG="${NIRUPI_DWM_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/suckless/dwm/config.h}"
[[ -r "$CONFIG" ]] || CONFIG="$HOME/.local/lib/nirupi/src/suckless/dwm/config.h"
CATEGORY_FILTER=""
MODE="picker"
while (($#)); do
  case "$1" in
    --list) MODE=list;;
    -c|--category) shift; CATEGORY_FILTER="${1:-}";;
    -h|--help) echo 'Usage: nirupi-keys.sh [--list] [-c CATEGORY]'; exit 0;;
    *) ;;
  esac
  shift || true
done

readable_mask() {
  local m="$1" out=""
  case "$m" in *MODKEY*) out="Super";; esac
  case "$m" in *ShiftMask*) out="${out:+$out+}Shift";; esac
  case "$m" in *ControlMask*) out="${out:+$out+}Ctrl";; esac
  case "$m" in *Mod1Mask*) out="${out:+$out+}Alt";; esac
  printf '%s' "$out"
}
readable_key() {
  printf '%s' "$1" | sed -e 's/^XK_//' -e 's/^XF86XK_//'
}

list_keybindings() {
  [[ -r "$CONFIG" ]] || return 0
  # Extract { MASK, KEY, func, ... } /* description */
  awk '
    /^[[:space:]]*\{/ && /(XK_|XF86XK_)/ && /\/\*/ {
      line=$0
      desc=line; sub(/^.*\/\*[[:space:]]*/,"",desc); sub(/[[:space:]]*\*\/.*$/,"",desc)
      sub(/^[^{]*\{/,"",line); sub(/\}.*$/,"",line)
      n=split(line,a,","); mask=a[1]; key=a[2]
      gsub(/[[:space:]]/,"",mask); gsub(/[[:space:]]/,"",key)
      if (key !~ /^(XK_|XF86XK_)/) next
      printf "%s\t%s\t%s\n", key, mask, desc
    }
  ' "$CONFIG" | while IFS=$'\t' read -r key mask desc; do
    printf 'KEY\t%s+%s\t%s\n' "$(readable_mask "$mask")" "$(readable_key "$key")" "$desc"
  done
}

list_apps() {
  # Apps/programs that are useful to launch directly (distinct from keybindings).
  cat <<'EOF'
APP	Terminal	kitty
APP	Files	pcmanfm
APP	Browser	nirupi-browser
APP	Agent (AI)	nirupi-agent
APP	Control center	nirupi-menu.sh
APP	Screenshot	screenshot-select.sh
APP	Clipboard	clip-menu.sh
EOF
}

emit() {
  { list_keybindings; list_apps; } | while IFS=$'\t' read -r kind label detail; do
    case "$kind" in
      KEY) printf ' ⌨  %-22s %s\n' "$label" "$detail";;
      APP) printf '  %-22s %s\n' "$label" "$detail";;
    esac
  done
}

if [[ -n "$CATEGORY_FILTER" ]]; then
  case "$CATEGORY_FILTER" in
    apps|app) list_apps | awk -F'\t' '{printf " %-22s %s\n",$2,$3}';;
    keys|keybindings) emit | grep '⌨' || true;;
    *) emit;;
  esac
  exit 0
fi

if [[ "$MODE" == list ]]; then emit; exit 0; fi

if command -v rofi >/dev/null 2>&1; then
  choice="$(emit | rofi -dmenu -i -p 'NIRUPI' -mesg 'Enter: keybindings are copied, apps are launched' -theme-str 'window {width: 40%;}')" || exit 0
elif command -v fzf >/dev/null 2>&1; then
  choice="$(emit | fzf --prompt 'NIRUPI > ' --height=80% --reverse)" || exit 0
else
  emit
  exit 0
fi
[[ -n "${choice:-}" ]] || exit 0

label="$(printf '%s' "$choice" | awk '{print $2}')"
kind="$(printf '%s' "$choice" | grep -q '⌨' && echo KEY || echo APP)"
if [[ "$kind" == KEY ]]; then
  printf '%s' "$label" | tr -d ' ' | { command -v xclip >/dev/null 2>&1 && xclip -selection clipboard || cat; } \
    && command -v notify-send >/dev/null 2>&1 && notify-send "NIRUPI" "Copied $label"
else
  case "$label" in
    Terminal) exec kitty;;
    Files) exec pcmanfm;;
    Browser) exec nirupi-browser;;
    Agent\(AI\)|Agent) exec nirupi-agent;;
    Control) exec nirupi-menu.sh;;
    Screenshot) exec screenshot-select.sh;;
    Clipboard) exec clip-menu.sh;;
    *) ;;
  esac
fi
