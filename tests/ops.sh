#!/usr/bin/env bash
# R6 ops & reliability: CI workflow, doctor --fix, scheduled backup.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }

CI="$ROOT/.github/workflows/ci.yml"
[[ -f $CI ]] || fail 'CI workflow missing'
grep -q 'debian:stable' "$CI" || fail 'CI missing Debian job'
grep -q 'archlinux' "$CI" || fail 'CI missing archlinux job'
grep -q 'tests/smoke.sh' "$CI" || fail 'CI does not run smoke'
grep -q 'shellcheck --severity=error' "$CI" || fail 'CI missing shellcheck step'
grep -q 'tools/package-list.sh' "$CI" || fail 'CI missing package manifest validation'
grep -q 'Build suckless' "$CI" || fail 'CI missing suckless build'

grep -q 'niru_doctor_fix' "$ROOT/runtime/nirupi" || fail 'doctor --fix missing'
grep -q -- '--fix' "$ROOT/runtime/nirupi" || fail 'doctor --fix flag missing'
grep -q 'xss-lock' "$ROOT/runtime/nirupi" || fail 'doctor --fix does not provision idle tool'

B="$ROOT/vendor/noir/local/bin/nirupi-backup.sh"
grep -q -- '--schedule' "$B" || fail 'backup --schedule missing'
grep -q -- '--unschedule' "$B" || fail 'backup --unschedule missing'
grep -q 'systemd\|crontab' "$B" || fail 'backup scheduler missing'

[[ -f "$ROOT/runtime/nirupi-update.sh" ]] || fail 'nirupi update helper missing'
grep -q 'update)' "$ROOT/runtime/nirupi" || fail 'nirupi update CLI missing'

# R7: optional whiptail installer TUI + keybindings generator.
grep -q 'whiptail' "$ROOT/install.sh" || fail 'installer TUI missing'
[[ -x "$ROOT/tools/gen-keybindings.sh" ]] || fail 'keybindings generator missing'
[[ -f "$ROOT/docs/KEYBINDINGS.md" ]] || fail 'KEYBINDINGS.md missing'

# Default personal repositories + Helium provisioning.
for r in nirupresence nirunote nplay; do
  grep -q "$r" "$ROOT/lib/apps.sh" || fail "default repo $r missing"
done
grep -q 'install_default_repos' "$ROOT/lib/install.sh" || fail 'install_default_repos not wired (apply path)'
# --theme-only and --update-dots must not clone repos or install a browser.
awk '/ACTION == theme \|\| ACTION == dots/,/^fi/' "$ROOT/install.sh" | grep -q 'install_default_repos\|ensure_helium\|ensure_slock' && fail 'theme-only branch has install side effects'
grep -q 'ensure_helium' "$ROOT/lib/install.sh" || fail 'ensure_helium missing'
grep -q 'pkg.helium.computer' "$ROOT/lib/install.sh" || fail 'Helium Debian repo missing'
grep -q 'helium.tar.xz' "$ROOT/lib/install.sh" || fail 'Helium tarball fallback missing'

# Leftovers: no legacy no-extension status-click symlink is created; the old
# overhaul roadmap docs are pruned.
! grep -q 'ln -sf nirupi-status-click.sh' "$ROOT/lib/install.sh" || fail 'legacy status-click symlink still created'
grep -q 'Removed legacy nirupi-status-click' "$ROOT/lib/install.sh" || fail 'legacy symlink cleanup missing'
for d in ROADMAP-v0.4.md ROADMAP-v0.6.md V0.3-OVERHAUL.md V0.4-OVERHAUL.md statusbar-upgrades.md; do
  [[ ! -e "$ROOT/docs/$d" ]] || fail "obsolete doc still present: $d"
done

# Bash syntax of the CI-adjacent scripts.
for f in "$ROOT/runtime/nirupi" "$B" "$ROOT/runtime/nirupi-update.sh"; do bash -n "$f"; done
echo 'PASS: ops (CI workflow, doctor --fix, scheduled backup, leftovers)'
