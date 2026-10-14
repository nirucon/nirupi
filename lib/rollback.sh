#!/usr/bin/env bash
# Unified, manifest-driven rollback.
#   nirupi rollback --binaries        restore the six NIRUPI binary links
#   nirupi rollback --configs [RUN]   restore user configs from a backup run
#   nirupi rollback --all             restore latest configs and then binaries
# Every path is validated before anything is modified; a local interactive TTY
# and explicit confirmation are always required.
# Sourced after lib/common.sh and lib/release.sh.

latest_backup_run(){
  local root="$STATE/backups" id
  [[ -d $root && ! -L $root ]] || return 0
  id="$(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r | head -n 1)"
  printf '%s' "$id"
}

_validate_config_backup(){
  local base="$1" f dest
  [[ -d $base && ! -L $base ]] || die "No config backup: $base"
  [[ -f $base/manifest.txt && ! -L $base/manifest.txt ]] || die "Missing/unsafe backup manifest: $base"
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    [[ $f == "$HOME"/* ]] || die "Unsafe backup path: $f"
    dest="$base$f"
    [[ -e $dest || -L $dest ]] || die "Backup payload missing: $dest"
  done < "$base/manifest.txt"
}

restore_config_backup(){
  local run="$1" base f dest
  [[ $run =~ ^[0-9]{8}-[0-9]{6}-[0-9]+$ ]] || die "Invalid backup run id: $run"
  base="$STATE/backups/$run"
  _validate_config_backup "$base"
  [[ -t 0 ]] || die 'Rollback requires an interactive terminal'
  printf 'Restore user configuration from backup %s? Type ROLLBACK: ' "$run"
  local ans; read -r ans
  [[ $ans == ROLLBACK ]] || die 'Cancelled'
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    dest="$base$f"
    mkdir -p -- "$(dirname "$f")"
    rm -f -- "$f"
    cp -a -- "$dest" "$f"
    printf 'RESTORED %s\n' "$f"
  done < "$base/manifest.txt"
  log 'User configuration restored. Packages and newly created files are NOT reverted.'
}

nih_rollback_all(){
  local run="${1:-}" base id app target link
  [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] || die 'Rollback requires a text TTY'
  [[ -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] || die 'Rollback over SSH refused'
  [[ -t 0 ]] || die 'Rollback requires an interactive terminal'
  run="${run:-$(latest_backup_run)}"
  [[ -n $run ]] || die 'No configuration backup available'
  base="$STATE/backups/$run"
  _validate_config_backup "$base"
  # Validate the latest binary snapshot before promising anything.
  release_safe_state
  local root; root="$(release_root)"
  [[ -d $root ]] || die 'No binary snapshot available'
  id="$(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r | head -n 1)"
  [[ $id =~ ^[0-9]{8}-[0-9]{6}-[0-9]+$ ]] || die 'No valid binary snapshot'
  [[ -f $root/$id/links.tsv && ! -L $root/$id/links.tsv ]] || die 'Unsafe binary snapshot manifest'
  printf 'Restore user configs (%s) and binary links (%s)? Type ROLLBACK: ' "$run" "$id"
  local ans; read -r ans
  [[ $ans == ROLLBACK ]] || die 'Cancelled'
  # Configuration first, then re-point the binary links.
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    mkdir -p -- "$(dirname "$f")"
    rm -f -- "$f"
    cp -a -- "$base$f" "$f"
    printf 'RESTORED %s\n' "$f"
  done < "$base/manifest.txt"
  while IFS=$'\t' read -r app target; do
    case " ${RELEASE_APPS[*]} " in *" $app "*) ;; *) die "Unexpected app in snapshot: $app";; esac
    link="$HOME/.local/bin/$app"
    if [[ $target == ABSENT ]]; then rm -f -- "$link"; continue; fi
    local tmp; tmp="$(mktemp "$HOME/.local/bin/.nirupi-rollback.XXXXXXXX")"
    rm -f -- "$tmp"
    ln -s -- "$target" "$tmp"
    mv -f -- "$tmp" "$link"
  done < "$root/$id/links.tsv"
  log 'Unified rollback complete (configs + binary links). Packages, SDDM and system files were NOT reverted.'
}

nirupi_rollback(){
  local mode="${1:-}"; shift || :
  case "$mode" in
    --binaries) release_rollback;;
    --configs) restore_config_backup "${1:-$(latest_backup_run)}";;
    --all) nih_rollback_all "${1:-}";;
    *) die 'Usage: nirupi rollback --all | --configs [RUN_ID] | --binaries';;
  esac
}
