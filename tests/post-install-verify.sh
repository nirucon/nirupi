#!/usr/bin/env bash
# Read-only installed-artifact verification; no root access or graphical login needed.
set -Eeuo pipefail
HOME_BIN="$HOME/.local/bin"
failed=0
expected_version="$(cat "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/VERSION")"
installed_version=''
for app in dwm dmenu st dmenu_run dmenu_path stest; do
 link="$HOME_BIN/$app"
 if [[ ! -L $link ]]; then echo "FAIL $app is not a managed symlink"; failed=1; continue; fi
 target="$(readlink -- "$link")"
 if [[ $target != "$HOME/.local/lib/nirupi/"* || ! -x $link ]]; then
  echo "FAIL $app target invalid: $target"; failed=1; continue
 fi
 version="${target#"$HOME/.local/lib/nirupi/"}"
 version="${version%%/*}"
 if [[ -n $installed_version && $installed_version != "$version" ]]; then
  echo "FAIL mixed binary versions: $installed_version and $version"; failed=1
 fi
 installed_version="$version"
 echo "OK  $app -> $version"
done
printf 'Installed binary version: %s | source version: %s\n' "${installed_version:-unknown}" "$expected_version"
if [[ -n $installed_version && $installed_version != "$expected_version" ]]; then
 echo "WARN installed version differs from checked-out source (expected before upgrade)"
fi
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
