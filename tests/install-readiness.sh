#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source_file="$ROOT/lib/install.sh"
# Isolate only the functions under test; never source installer side effects.
eval "$(sed -n '/^check_home_path_safety() {/,/^}/p' "$source_file")"
eval "$(sed -n '/^check_display_manager_conflicts() {/,/^}/p' "$source_file")"
die(){ printf 'BLOCKED %s\n' "$*" >&2; return 1; }
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"
export STATE="$HOME/.local/state/nirupi" SESSION=startx DISTRO=debian
check_home_path_safety
mkdir -p "$HOME/.config"
ln -s /tmp "$HOME/.config/suckless"
if (check_home_path_safety) >/dev/null 2>&1; then echo 'FAIL: unsafe symlink accepted' >&2; exit 1; fi
rm "$HOME/.config/suckless"
mkdir -p "$HOME/.config/suckless/dwm"
check_home_path_safety
mkdir -p "$HOME/.local/state"
ln -s /tmp "$STATE"
if (check_home_path_safety) >/dev/null 2>&1; then echo 'FAIL: symlink state accepted' >&2; exit 1; fi
rm "$STATE"
check_home_path_safety
check_display_manager_conflicts
printf 'PASS: home path collision and state symlink safety\n'
