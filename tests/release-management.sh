#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $(id -u) -ne 0 ]] || { echo 'SKIP: release test requires non-root'; exit 0; }
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
export HOME="$work/home" XDG_STATE_HOME="$work/home/.local/state"
mkdir -p "$HOME/.local/bin" "$HOME/.local/lib/nirupi/0.2.0-alpha.32/old/bin"
for app in dwm dmenu st dmenu_run dmenu_path stest; do
 target="$HOME/.local/lib/nirupi/0.2.0-alpha.32/old/bin/$app"
 printf '#!/bin/sh\nexit 0\n' > "$target"; chmod 755 "$target"
 ln -s "$target" "$HOME/.local/bin/$app"
done
# Load functions without sourcing production common.sh's distro detection.
STATE="$XDG_STATE_HOME/nirupi" VERSION=0.2.0-beta.1
log(){ :; }; die(){ echo "FAIL: $*" >&2; exit 1; }
check_home_path_safety(){
 for path in "$HOME/.local" "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/lib/nirupi" "$XDG_STATE_HOME" "$STATE"; do
  [[ ! -L $path && ( ! -e $path || -d $path ) ]] || die "unsafe path: $path"
 done
}
source "$ROOT/lib/release.sh"
release_snapshot 20261008-120000-1234
for app in "${RELEASE_APPS[@]}"; do
 target="$HOME/.local/lib/nirupi/0.2.0-beta.1/new/bin/$app"
 mkdir -p "$(dirname "$target")"
 printf '#!/bin/sh\nexit 0\n' > "$target"; chmod 755 "$target"
 ln -sfn "$target" "$HOME/.local/bin/$app"
done
printf 'ROLLBACK\n' | { :; } # interactive rollback is tested through a pseudo-TTY below.
[[ $(wc -l < "$STATE/release-snapshots/20261008-120000-1234/links.tsv") == 6 ]]
[[ $(release_history | head -1) == 20261008-120000-1234 ]]
# Manifest should reject unexpected executable paths.
printf 'rogue\t/tmp/rogue\n' >> "$STATE/release-snapshots/20261008-120000-1234/links.tsv"
if ( release_rollback </dev/null ) >/dev/null 2>&1; then echo 'FAIL: noninteractive rollback accepted'; exit 1; fi
sed -i '$d' "$STATE/release-snapshots/20261008-120000-1234/links.tsv"
for app in "${RELEASE_APPS[@]}"; do
 grep -Fq "0.2.0-alpha.32/old/bin/$app" "$STATE/release-snapshots/20261008-120000-1234/links.tsv"
done
echo 'PASS: release snapshots, versioned links, history and noninteractive rollback guard'
