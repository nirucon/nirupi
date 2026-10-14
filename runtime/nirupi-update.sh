#!/usr/bin/env bash
# Update the NIRUPI source checkout and show what changed.
#   nirupi update
# Set NIRUPI_REPO to point at your checkout (default ~/Git/nirupi).
set -Eeuo pipefail
repo="${NIRUPI_REPO:-$HOME/Git/nirupi}"
if [[ ! -d "$repo/.git" ]]; then
  printf 'No NIRUPI git checkout at %s (set NIRUPI_REPO)\n' "$repo" >&2
  exit 1
fi
before="$(cat "$repo/VERSION" 2>/dev/null || echo unknown)"
printf 'Updating %s ...\n' "$repo"
git -C "$repo" pull --ff-only
after="$(cat "$repo/VERSION" 2>/dev/null || echo unknown)"
printf 'Version: %s -> %s\n' "$before" "$after"
printf '\nNext steps (from a local text TTY):\n'
printf '  bash %s/install.sh --diff    # review changes\n' "$repo"
printf '  bash %s/install.sh --apply   # full upgrade (packages + rebuild dwm)\n' "$repo"
printf 'Or, to only refresh scripts/theme without packages:\n'
printf '  bash %s/install.sh --update-dots\n' "$repo"
