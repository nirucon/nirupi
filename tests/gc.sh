#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" XDG_STATE_HOME="$TMP/state" NIRUPI_KEEP_VERSIONS=1 NIRUPI_KEEP_SNAPSHOTS=1
mkdir -p "$HOME/.local/lib/nirupi/0.1/bin" "$HOME/.local/lib/nirupi/0.2/bin" "$HOME/.local/lib/nirupi/0.3/bin" \
         "$XDG_STATE_HOME/nirupi/release-snapshots/20260101-000000-1" "$XDG_STATE_HOME/nirupi/release-snapshots/20260102-000000-2"
printf 'NIRUPI_VERSION=0.3\n' > "$XDG_STATE_HOME/nirupi/installed.env"

plan="$("$ROOT/runtime/nirupi-gc.sh" --dry-run)"
echo "$plan" | grep -q 'nirupi/0.1' || { echo "FAIL: old version not listed" >&2; exit 1; }
echo "$plan" | grep -q 'nirupi/0.2/bin' && { echo "FAIL: kept version listed" >&2; exit 1; }
echo "$plan" | grep -q '20260101-000000-1' || { echo "FAIL: old snapshot not listed" >&2; exit 1; }
"$ROOT/runtime/nirupi-gc.sh" --yes >/dev/null
[[ ! -d "$HOME/.local/lib/nirupi/0.1" && -d "$HOME/.local/lib/nirupi/0.2" && -d "$HOME/.local/lib/nirupi/0.3" ]] || { echo "FAIL: version prune wrong" >&2; exit 1; }
[[ ! -d "$XDG_STATE_HOME/nirupi/release-snapshots/20260101-000000-1" && -d "$XDG_STATE_HOME/nirupi/release-snapshots/20260102-000000-2" ]] || { echo "FAIL: snapshot prune wrong" >&2; exit 1; }

# A version referenced by a retained snapshot must be preserved even with KEEP_VERSIONS=0.
mkdir -p "$HOME/.local/lib/nirupi/0.4/bin"
snap="$XDG_STATE_HOME/nirupi/release-snapshots/20260103-000000-3"
mkdir -p "$snap"
printf 'dwm\t%s\n' "$HOME/.local/lib/nirupi/0.4/bin/dwm" > "$snap/links.tsv"
printf 'NIRUPI_VERSION=0.3\n' > "$XDG_STATE_HOME/nirupi/installed.env"
plan="$(NIRUPI_KEEP_VERSIONS=0 NIRUPI_KEEP_SNAPSHOTS=1 "$ROOT/runtime/nirupi-gc.sh" --dry-run)"
echo "$plan" | grep -q 'nirupi/0.4' && { echo "FAIL: snapshot-protected version listed" >&2; exit 1; }
echo 'PASS: nirupi gc prunes old versions/snapshots and preserves rollback targets'
