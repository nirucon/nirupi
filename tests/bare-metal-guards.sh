#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash -n "$ROOT/install.sh" "$ROOT/tests/post-install-verify.sh" "$ROOT/tests/bare-metal-readiness.sh"
grep -Fq 'check_display_manager_conflicts' "$ROOT/install.sh"
grep -Fq 'check_home_path_safety' "$ROOT/install.sh"
grep -Fq 'Archive verification failed' "$ROOT/lib/migrate.sh"
grep -Fq 'Refusing to archive path outside HOME' "$ROOT/lib/migrate.sh"
echo 'PASS: bare-metal preflight and safe migration archival guards'
