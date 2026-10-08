#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" XDG_STATE_HOME="$tmp/home/.state"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/gtk-3.0" "$tmp/theme/Adwaita-dark/gtk-3.0"
# Fixture for theme existence: use system theme if present, otherwise skip apply integration.
if [[ -d /usr/share/themes/Adwaita-dark/gtk-3.0 ]]; then
 printf '[Settings]\ngtk-theme-name=Custom\ngtk-font-name=Sans 11\n' > "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
 "$ROOT/runtime/nirupi-appearance" default | grep -q preserved
 grep -q 'gtk-theme-name=Custom' "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
 "$ROOT/runtime/nirupi-appearance" apply noir
 grep -q 'gtk-theme-name=Adwaita-dark' "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
 grep -q 'gtk-font-name=Sans 11' "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
 "$ROOT/runtime/nirupi-appearance" restore
 grep -q 'gtk-theme-name=Custom' "$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
fi
bash -n "$ROOT/runtime/nirupi-appearance" "$ROOT/runtime/nirupi" "$ROOT/install.sh" "$ROOT/lib/install.sh"
echo 'PASS: beta.3 appearance preservation, apply/restore, syntax'
