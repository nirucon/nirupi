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
# Take a system snapshot before a risky update, when the machine has a backend.
if [[ -x "$HOME/.local/bin/nirupi-snapshot.sh" ]]; then
  "$HOME/.local/bin/nirupi-snapshot.sh" create "nirupi update $before" || \
    printf 'WARN no system snapshot taken; continuing\n' >&2
fi
printf 'Updating %s ...\n' "$repo"
git -C "$repo" pull --ff-only
after="$(cat "$repo/VERSION" 2>/dev/null || echo unknown)"
printf 'Version: %s -> %s\n' "$before" "$after"
if [[ "$before" != "$after" && -f "$repo/CHANGELOG.md" ]]; then
  printf '\nChanges in this update:\n'
  awk -v stop="## $before" 'index($0, stop) == 1 { exit } /^## / { show = 1 } show { print }' "$repo/CHANGELOG.md"
fi

# Refresh the deployed bundle (scripts, theme, session config). Also updates the
# dwm sources under ~/.local/lib so `reload` can rebuild from the new checkout.
if [[ -x "$repo/install.sh" ]]; then
  printf '\nRefreshing scripts + theme ...\n'
  bash "$repo/install.sh" --update-dots || printf 'WARN update-dots failed; run it manually\n' >&2
fi

# Ensure the binaries for the current version exist and are linked. --update-dots
# refreshes scripts but does not build, so a version bump can otherwise leave the
# links pointing at an older build.
ver="$(cat "$repo/VERSION" 2>/dev/null || true)"
if [[ -n $ver && ! -x "$HOME/.local/lib/nirupi/$ver/bin/dwm" ]]; then
  printf '\nBuilding the binaries for %s ...\n' "$ver"
  "$HOME/.local/bin/nirupi" migrate binaries --rebuild || printf 'WARN binary rebuild failed\n' >&2
fi

# Rebuild dwm only if its sources changed, then restart it in place.
if [[ -x "$HOME/.local/bin/nirupi-reload.sh" ]]; then
  printf '\nRebuilding dwm if needed ...\n'
  "$HOME/.local/bin/nirupi" reload || printf 'WARN reload failed; run: nirupi reload\n' >&2
fi

printf '\nPackages and other system changes (if any) still need a full upgrade from a local TTY:\n'
printf '  bash %s/install.sh --apply\n' "$repo"
