#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
cat > "$TEMP/checkupdates" <<'EOF'
#!/bin/sh
printf 'pkg1 1 -> 2\npkg2 1 -> 2\n'
EOF
chmod +x "$TEMP/checkupdates"
result="$(PATH="$TEMP:/usr/bin:/bin" "$ROOT/runtime/nirupi-updates")"
[[ "$result" == 2 ]] || { printf 'FAIL: expected 2 updates, got %s\n' "$result"; exit 1; }
cat > "$TEMP/checkupdates" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$TEMP/checkupdates"
result="$(PATH="$TEMP:/usr/bin:/bin" "$ROOT/runtime/nirupi-updates")"
[[ "$result" == 0 ]] || { printf 'FAIL: expected numeric 0 on helper failure, got %s\n' "$result"; exit 1; }
printf 'PASS: update adapter counts packages and fails safely\n'
