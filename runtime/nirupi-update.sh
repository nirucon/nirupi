#!/usr/bin/env bash
# Update the NIRUPI source checkout, refresh scripts/theme, and rebuild+restart
# dwm if its sources changed. Packages still need a full upgrade from a TTY.
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

# Refresh the deployed bundle (scripts, theme, session config). Also updates the
# dwm sources under ~/.local/lib so `reload` can rebuild from the new checkout.
if [[ -x "$repo/install.sh" ]]; then
  printf '\nRefreshing scripts + theme ...\n'
  bash "$repo/install.sh" --update-dots || printf 'WARN update-dots failed; run it manually\n' >&2
fi

# Rebuild dwm only if its sources changed, then restart it in place.
if [[ -x "$HOME/.local/bin/nirupi-reload.sh" ]]; then
  printf '\nRebuilding dwm if needed ...\n'
  "$HOME/.local/bin/nirupi" reload || printf 'WARN reload failed; run: nirupi reload\n' >&2
fi

printf '\nPackages and other system changes (if any) still need a full upgrade from a local TTY:\n'
printf '  bash %s/install.sh --apply\n' "$repo"
