#!/usr/bin/env bash
# Show the CHANGELOG entry for the installed NIRUPI version (or a given one).
set -Eeuo pipefail
lib="${NIRUPI_LIB_ROOT:-$HOME/.local/lib/nirupi}"
cl="$lib/CHANGELOG.md"
[[ -f $cl ]] || { printf 'No changelog at %s\n' "$cl" >&2; exit 1; }
v="${1:-$(cat "$lib/VERSION" 2>/dev/null)}"
awk -v want="## $v" '
  index($0, want) == 1 { show = 1; print; next }
  show && /^## / { exit }
  show { print }
' "$cl"
