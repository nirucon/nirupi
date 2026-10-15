#!/usr/bin/env bash
# NIRUPI garbage collector: prune old versioned binaries and stale state.
#   nirupi gc [--dry-run] [--yes] [--legacy]
# Safety: version directories referenced by the retained release snapshots are
# never removed, so `nirupi rollback` keeps working. Keeps the current version,
# the newest NIRUPI_KEEP_VERSIONS older ones, the newest NIRUPI_KEEP_SNAPSHOTS
# release snapshots and the newest NIRUPI_KEEP_BACKUPS backup/migration runs.
# --legacy also prunes old legacy archives (kept by default).
set -Eeuo pipefail
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nirupi"
LIBROOT="$HOME/.local/lib/nirupi"
KEEP_VERSIONS="${NIRUPI_KEEP_VERSIONS:-1}"
KEEP_SNAPSHOTS="${NIRUPI_KEEP_SNAPSHOTS:-3}"
KEEP_BACKUPS="${NIRUPI_KEEP_BACKUPS:-5}"
DRY=0; ASSUME=0; LEGACY=0
while (($#)); do
  case "$1" in
    --dry-run) DRY=1;; --yes) ASSUME=1;; --legacy) LEGACY=1;;
    -h|--help) echo 'Usage: nirupi gc [--dry-run] [--yes] [--legacy]'; exit 0;;
    *) echo "Unknown option: $1" >&2; exit 2;;
  esac
  shift
done

current="$(sed -n 's/^NIRUPI_VERSION=//p' "$STATE/installed.env" 2>/dev/null | head -n1)"
if [[ -z $current ]]; then
  link="$(readlink -f "$HOME/.local/bin/dwm" 2>/dev/null || true)"
  current="$(printf '%s' "$link" | sed -n 's#.*/nirupi/\([^/]*\)/.*#\1#p')"
fi

targets=()

# Release snapshots (newest first).
snap_root="$STATE/release-snapshots"
snaps=()
if [[ -d $snap_root ]]; then
  mapfile -t snaps < <(find "$snap_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r)
fi

# A snapshot is a usable rollback anchor only if every version directory it
# references still exists. Stale snapshots are pruned and protect nothing.
snapshot_is_stale(){
  local f="$snap_root/$1/links.tsv" rest v
  [[ -f $f && ! -L $f ]] || return 1
  while IFS=$'\t' read -r app tgt; do
    [[ $tgt == "$LIBROOT/"* ]] || continue
    rest="${tgt#"$LIBROOT"/}"; v="${rest%%/*}"
    [[ -d $LIBROOT/$v ]] || return 0
  done < "$f"
  return 1
}

# Keep the newest KEEP_SNAPSHOTS usable snapshots and protect the version dirs
# they reference; prune the rest (stale, or beyond the keep count).
retained_snaps=()
protected=()
for sn in "${snaps[@]}"; do
  if snapshot_is_stale "$sn" || (( ${#retained_snaps[@]} >= KEEP_SNAPSHOTS )); then
    targets+=("$snap_root/$sn")
    continue
  fi
  retained_snaps+=("$sn")
  f="$snap_root/$sn/links.tsv"
  [[ -f $f && ! -L $f ]] || continue
  while IFS=$'\t' read -r app tgt; do
    [[ $tgt == "$LIBROOT/"* ]] || continue
    rest="${tgt#"$LIBROOT"/}"; protected+=("${rest%%/*}")
  done < "$f"
done

# Versions referenced by installed symlinks must be preserved too: a component
# can still point at an older version when only some were rebuilt.
if [[ -d $HOME/.local/bin ]]; then
  for lnk in "$HOME"/.local/bin/*; do
    [[ -L $lnk ]] || continue
    tgt="$(readlink -f "$lnk" 2>/dev/null || true)"
    [[ $tgt == "$LIBROOT/"* ]] || continue
    rest="${tgt#"$LIBROOT"/}"; protected+=("${rest%%/*}")
  done
fi

# Versioned binary dirs: keep current + protected + newest KEEP_VERSIONS.
if [[ -d $LIBROOT ]]; then
  mapfile -t all < <(find "$LIBROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | grep -E '^[0-9]' | sort -V)
  keep=("$current")
  for ((i=0; i<=KEEP_VERSIONS && i<${#all[@]}; i++)); do keep+=("${all[${#all[@]}-1-i]}"); done
  keep+=("${protected[@]}")
  for v in "${all[@]}"; do
    skip=0
    for k in "${keep[@]}"; do if [[ $v == "$k" ]]; then skip=1; fi; done
    if (( skip == 0 )); then targets+=("$LIBROOT/$v"); fi
  done
fi

# Old release snapshots are handled above (stale or beyond KEEP_SNAPSHOTS).

prune_dir() {
  local root="$1" keep="$2" d
  [[ -d $root ]] || return 0
  local list; list="$(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r)"
  local n=0
  while IFS= read -r d; do
    if [[ -z $d ]]; then continue; fi
    if (( n < keep )); then n=$(( n + 1 )); continue; fi
    targets+=("$root/$d")
  done <<< "$list"
  return 0
}
prune_dir "$STATE/backups" "$KEEP_BACKUPS"
prune_dir "$STATE/migrations" "$KEEP_BACKUPS"
if (( LEGACY )); then prune_dir "$STATE/legacy" "$KEEP_BACKUPS"; fi

if ((${#targets[@]} == 0)); then echo 'Nothing to prune'; exit 0; fi
echo "NIRUPI gc will remove:"
for t in "${targets[@]}"; do
  sz="$(du -sh "$t" 2>/dev/null | cut -f1)"
  printf '  %-8s %s\n' "${sz:-?}" "$t"
done
if (( DRY )); then echo '(dry run; nothing removed)'; exit 0; fi
if (( ASSUME == 0 )); then
  [[ -t 0 ]] || { echo 'Refusing without --yes on a non-interactive terminal' >&2; exit 1; }
  printf 'Type GC to remove these paths: '; read -r ans
  [[ $ans == GC ]] || { echo 'Cancelled'; exit 1; }
fi
for t in "${targets[@]}"; do rm -rf -- "$t"; done
echo "Removed ${#targets[@]} path(s)."
