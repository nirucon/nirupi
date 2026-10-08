#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash -n "$ROOT/install.sh" "$ROOT/migrate-desktop.sh" "$ROOT/tests/post-install-verify.sh" "$ROOT/tests/bare-metal-readiness.sh"
grep -Fq 'check_display_manager_conflicts' "$ROOT/install.sh"
grep -Fq 'check_home_path_safety' "$ROOT/install.sh"
grep -Fq 'Backup verification failed' "$ROOT/migrate-desktop.sh"
grep -Fq 'Rollback path outside migration scope' "$ROOT/migrate-desktop.sh"
echo 'PASS: bare-metal preflight, migration and rollback guards'
