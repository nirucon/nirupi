#!/usr/bin/env bash
# R4 web apps: Helium-first launchers + nirupi webapp add/list/remove.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }

grep -q 'BROWSER_PREF=(helium-browser helium brave' "$ROOT/vendor/noir/local/bin/webapp-dmenu.sh" \
  || grep -q 'BROWSER_PREF=(helium helium-browser brave' "$ROOT/vendor/noir/local/bin/webapp-dmenu.sh" \
  || fail 'webapp-dmenu.sh is not Helium-first'
grep -q 'helium' "$ROOT/runtime/nirupi-browser" || fail 'nirupi-browser does not prefer helium'

W="$ROOT/vendor/noir/local/bin/nirupi-webapp.sh"
[[ -x $W ]] || fail 'nirupi-webapp.sh missing/not executable'
grep -q 'nirupi-webapp.sh' "$ROOT/lib/install.sh" || fail 'webapp helper not deployed'
grep -q 'webapp)' "$ROOT/runtime/nirupi" || fail 'nirupi webapp CLI missing'

# Functional: create, list and remove a webapp with a fake Helium backend.
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin"
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/helium"; chmod +x "$TMP/bin/helium"
run(){ HOME="$TMP/home" PATH="$TMP/bin:$PATH" XDG_CONFIG_HOME="$TMP/home/.config" bash "$W" "$@"; }
run add "Example App" "https://example.com/" >/dev/null
d="$TMP/home/.local/share/applications/exampleapp.desktop"
[[ -f $d ]] || fail 'desktop entry not created'
grep -q '^X-NIRUPI-WebApp=true$' "$d" || fail 'missing managed marker'
grep -q '^X-NIRUPI-URL=https://example.com/$' "$d" || fail 'missing url marker'
grep -q '^StartupWMClass=WebApp-exampleapp$' "$d" || fail 'missing WM class'
grep -q -- '--app=' "$TMP/home/.local/bin/exampleapp" || fail 'launcher lacks --app'
grep -q -- '--class=' "$TMP/home/.local/bin/exampleapp" || fail 'launcher lacks --class'
grep -Eq "CLASS=.?WebApp-exampleapp.?" "$TMP/home/.local/bin/exampleapp" || fail 'launcher class wrong'
run list | grep -q 'Example App' || fail 'list did not show app'
run remove "Example App" >/dev/null
[[ ! -e $d ]] || fail 'remove left the desktop entry'
echo 'PASS: webapps (Helium-first, nirupi webapp add/list/remove)'
