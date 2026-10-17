#!/usr/bin/env bash
# dwm state persistence, runtime rules, complete theming and scriptable control.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DWM="$ROOT/vendor/suckless/dwm"
SLOCK="$ROOT/vendor/suckless/slock"
fail(){ echo "FAIL: $*" >&2; exit 1; }
grep -q 'savestate(void)' "$DWM/dwm.c" || fail 'savestate missing'
grep -q 'loadstate(void)' "$DWM/dwm.c" || fail 'loadstate missing'
grep -q 'applyuserrules' "$DWM/dwm.c" || fail 'runtime rules missing'
grep -q 'layout0' "$DWM/dwm.c" || fail 'layout persistence incomplete'
grep -q 'rules.conf' "$ROOT/lib/install.sh" || fail 'rules example not deployed'
grep -q 'missions.conf' "$ROOT/lib/install.sh" || fail 'missions example not deployed'
grep -q 'slock.clockFont' "$ROOT/lib/theme.sh" || fail 'slock theme not generated'
grep -q 'xresload' "$SLOCK/slock.c" || fail 'slock does not read Xresources'
grep -q 'NIRUPI_C_BG' "$ROOT/runtime-session.sh" || fail 'session background is not themed'
grep -q 'Super+Ctrl+D' "$ROOT/docs/KEYBINDINGS.md" || fail 'explain binding not documented'
grep -q 'Super+Ctrl+M' "$ROOT/docs/KEYBINDINGS.md" || fail 'mission binding not documented'
echo 'PASS: dwm state/rules/theming and scriptable control'
