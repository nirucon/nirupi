#!/usr/bin/env bash
# R6 ops & reliability: CI workflow, doctor --fix, scheduled backup.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }

CI="$ROOT/.github/workflows/ci.yml"
[[ -f $CI ]] || fail 'CI workflow missing'
grep -q 'ubuntu-latest' "$CI" || fail 'CI missing ubuntu job'
grep -q 'archlinux' "$CI" || fail 'CI missing archlinux job'
grep -q 'tests/smoke.sh' "$CI" || fail 'CI does not run smoke'
grep -q 'shellcheck --severity=error' "$CI" || fail 'CI missing shellcheck step'

grep -q 'niru_doctor_fix' "$ROOT/runtime/nirupi" || fail 'doctor --fix missing'
grep -q -- '--fix' "$ROOT/runtime/nirupi" || fail 'doctor --fix flag missing'
grep -q 'xss-lock' "$ROOT/runtime/nirupi" || fail 'doctor --fix does not provision idle tool'

B="$ROOT/vendor/noir/local/bin/nirupi-backup.sh"
grep -q -- '--schedule' "$B" || fail 'backup --schedule missing'
grep -q -- '--unschedule' "$B" || fail 'backup --unschedule missing'
grep -q 'systemd\|crontab' "$B" || fail 'backup scheduler missing'

[[ -f "$ROOT/runtime/nirupi-update.sh" ]] || fail 'nirupi update helper missing'
grep -q 'update)' "$ROOT/runtime/nirupi" || fail 'nirupi update CLI missing'

# Bash syntax of the CI-adjacent scripts.
for f in "$ROOT/runtime/nirupi" "$B" "$ROOT/runtime/nirupi-update.sh"; do bash -n "$f"; done
echo 'PASS: ops (CI workflow, doctor --fix, scheduled backup)'
