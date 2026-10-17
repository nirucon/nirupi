#!/usr/bin/env bash
# R3 session & effects: idle ladder, lock-on-suspend, logout confirm, night light.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/vendor/suckless/dwm/config.h"
fail(){ echo "FAIL: $*" >&2; exit 1; }

# Idle ladder in runtime-session.sh + session.conf.example.
S="$ROOT/runtime-session.sh"
for v in IDLE_DIM_MINUTES IDLE_LOCK_MINUTES IDLE_DPMS_MINUTES IDLE_SUSPEND_MINUTES LOCK_ON_SUSPEND; do
  grep -q "$v" "$S" || fail "runtime-session.sh missing $v"
  grep -q "$v" "$ROOT/runtime/session.conf.example" || fail "session.conf.example missing $v"
done
grep -q 'xidlehook' "$S" || fail 'xidlehook ladder missing'
grep -q 'xautolock' "$S" || fail 'xautolock fallback missing'
grep -q 'xss-lock' "$S" || fail 'xss-lock fallback missing'
grep -q -- '--transfer-sleep-lock' "$S" || fail 'lock-on-suspend missing'

# Logout confirmation instead of immediate quit.
[[ -f "$ROOT/vendor/noir/local/bin/nirupi-logout.sh" ]] || fail 'logout helper missing'
grep -q 'logoutcmd' "$CFG" || fail 'logoutcmd not bound'
grep -q 'nirupi-logout.sh' "$ROOT/lib/install.sh" || fail 'logout helper not deployed'
! grep -Eq 'MODKEY\|ShiftMask, +XK_q, +quit' "$CFG" || fail 'Super+Shift+q still quits immediately'

# Night light.
[[ -f "$ROOT/vendor/noir/local/bin/nirupi-nightlight.sh" ]] || fail 'nightlight helper missing'
grep -q 'nightlightcmd' "$CFG" || fail 'nightlight binding missing'
grep -q 'gammastep' "$ROOT/vendor/noir/local/bin/nirupi-nightlight.sh" || fail 'gammastep missing'
grep -q 'redshift' "$ROOT/lib/packages.sh" || fail 'redshift not in OPTIONAL_PKGS'
grep -q 'Night light: cycle' "$ROOT/vendor/noir/local/bin/nirupi-menu.sh" || fail 'menu night light missing'

# Suspend helper must detect the (privilege-dropping) locker with pgrep, not kill -0.
SS="$ROOT/vendor/noir/local/bin/sleep-suspend.sh"
grep -q 'pgrep -x slock' "$SS" || fail 'sleep-suspend.sh does not use pgrep'
! grep -q 'kill -0' "$SS" || fail 'sleep-suspend.sh still uses kill -0 (fails on a nobody-owned slock)'
# Lock, wait SUSPEND_DELAY_SECONDS, and cancel the suspend if the user unlocks.
grep -q 'SUSPEND_DELAY_SECONDS' "$SS" || fail 'sleep-suspend.sh ignores SUSPEND_DELAY_SECONDS'
grep -q 'Suspend cancelled' "$SS" || fail 'sleep-suspend.sh does not cancel on unlock'
grep -q 'SUSPEND_DELAY_SECONDS' "$ROOT/runtime/session.conf.example" || fail 'session.conf.example lacks SUSPEND_DELAY_SECONDS'

# Lock wrapper deployed and setuid slock provisioned on install/update.
grep -q 'nirupi-lock.sh' "$ROOT/lib/install.sh" || fail 'lock wrapper not deployed'
grep -q 'ensure_slock' "$ROOT/lib/install.sh" || fail 'ensure_slock missing'
grep -q 'ensure_slock' "$ROOT/lib/install.sh" || fail 'ensure_slock not wired into apply path'
grep -q 'nirupi-lock.sh' "$ROOT/vendor/noir/local/bin/nirupi-menu.sh" || fail 'control center does not use nirupi-lock.sh'
echo 'PASS: session effects (idle ladder, lock-on-suspend, logout confirm, night light, setuid slock)'
