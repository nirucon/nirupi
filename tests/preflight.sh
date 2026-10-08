#!/usr/bin/env bash
# Read-only source integrity and deployment preflight.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
check(){ if [[ ! -f "$ROOT/$1" ]]; then printf 'MISSING %s\n' "$1" >&2; fail=1; fi; }
for app in dwm dmenu st slock; do
 check "vendor/suckless/$app/Makefile"
 check "vendor/suckless/$app/config.mk"
done
for file in vendor/sddm/Main.qml vendor/sddm/theme.conf vendor/noir/dotfiles/.Xresources runtime-session.sh runtime-xinitrc runtime/nirupi-updates; do check "$file"; done
for helper in dwm-status.sh wallrotate.sh wallpaperchange.sh dwm-keybindings.sh screenshot-select.sh screenshot-browser.sh clip-menu.sh clip-save.sh webapp-dmenu.sh; do check "vendor/noir/local/bin/$helper"; done
for file in "$ROOT"/vendor/noir/local/bin/*.sh; do bash -n "$file" || fail=1; done
for file in "$ROOT"/install.sh "$ROOT"/lib/*.sh "$ROOT"/tests/*.sh; do bash -n "$file" || fail=1; done
if ((fail)); then echo 'FAIL: source preflight' >&2; exit 1; fi
echo 'PASS: source assets and Bash syntax'
