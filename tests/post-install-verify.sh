#!/usr/bin/env bash
# Read-only installed-artifact verification; no root access or graphical login needed.
set -Eeuo pipefail
HOME_BIN="$HOME/.local/bin"
failed=0
for app in dwm dmenu st dmenu_run dmenu_path stest nirupi-session; do
 if [[ -x "$HOME_BIN/$app" ]]; then printf 'OK  %s\n' "$app"; else printf 'FAIL %s missing or not executable\n' "$app"; failed=1; fi
done
for file in "$HOME/.Xresources" "$HOME/.config/suckless/dwm/config.h"; do
 if [[ -f $file ]]; then printf 'OK  %s\n' "$file"; else printf 'FAIL %s missing\n' "$file"; failed=1; fi
done
if [[ -f /usr/share/xsessions/nirupi-dwm.desktop ]]; then
 grep -Fxq 'Exec=/usr/local/bin/nirupi-session' /usr/share/xsessions/nirupi-dwm.desktop || { echo 'FAIL desktop entry launcher'; failed=1; }
else echo 'FAIL desktop entry missing'; failed=1; fi
if [[ -x /usr/local/bin/nirupi-session ]]; then echo 'OK  system session launcher'; else echo 'FAIL system session launcher'; failed=1; fi
if (( failed )); then echo 'FAIL installed artifact verification'; exit 1; fi
echo 'PASS installed artifacts (graphical session still requires real login test)'
