#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" STATE="$TMP/state"
mkdir -p "$HOME/.local/bin" "$HOME/.config/suckless/dwm" "$STATE"
eval "$(sed -n '/^check_user_install_conflicts() {/,/^}/p' "$ROOT/lib/install.sh")"
die(){ printf '%s\n' "$*" >&2; exit 1; }
warn(){ :; }
check_user_install_conflicts
printf 'custom DWM\n' > "$HOME/.config/suckless/dwm/config.h"
check_user_install_conflicts
ln -s /bin/true "$HOME/.local/bin/dwm"
if (check_user_install_conflicts) >/dev/null 2>&1; then echo 'FAIL: unmanaged DWM symlink accepted' >&2; exit 1; fi
rm "$HOME/.local/bin/dwm"
printf 'foreign\n' > "$HOME/.local/bin/dwm"
if (check_user_install_conflicts) >/dev/null 2>&1; then echo 'FAIL: foreign DWM executable accepted' >&2; exit 1; fi
rm "$HOME/.local/bin/dwm"
ln -s /bin/true "$HOME/.config/suckless/dwm/config.h".link
mv "$HOME/.config/suckless/dwm/config.h" "$HOME/.config/suckless/dwm/config.h".original
mv "$HOME/.config/suckless/dwm/config.h".link "$HOME/.config/suckless/dwm/config.h"
if (check_user_install_conflicts) >/dev/null 2>&1; then echo 'FAIL: DWM config symlink accepted' >&2; exit 1; fi
rm "$HOME/.config/suckless/dwm/config.h"
mv "$HOME/.config/suckless/dwm/config.h".original "$HOME/.config/suckless/dwm/config.h"
ln -s /tmp/foreign "$STATE/managed-configs.tsv"
if (check_user_install_conflicts) >/dev/null 2>&1; then echo 'FAIL: manifest symlink accepted' >&2; exit 1; fi
rm "$STATE/managed-configs.tsv"
mkdir -p "$HOME/.config/kitty"
check_user_install_conflicts
printf 'PASS: pre-package collision checks are read-only and reject unsafe inputs\n'
