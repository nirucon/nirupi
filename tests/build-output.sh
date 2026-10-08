#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$ROOT/lib/install.sh"
grep -Fq 'Validate every build output before installing the first executable.' "$INSTALL"
grep -Fq 'Missing dmenu helper: $app' "$INSTALL"
grep -Fq 'Missing executable build output: $app' "$INSTALL"
grep -Fq 'Existing /usr/local/bin/nirupi-session is unmanaged' "$INSTALL"
printf 'PASS: build-output and session-entry pre-deployment guards\n'
