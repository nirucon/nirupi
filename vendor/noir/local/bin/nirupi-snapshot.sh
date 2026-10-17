#!/usr/bin/env bash
# NIRUPI snapshot — take a system snapshot before a risky update when the
# machine already has a supported snapshot backend.
#
#   nirupi snapshot status
#   nirupi snapshot create [REASON] [--yes]
#   nirupi snapshot list
#
# Supported backends (in order): timeshift, snapper, ZFS, btrfs (read-only
# snapshot only when /.snapshots is writable). This is intentionally a thin
# wrapper: it never installs a backend and never guesses an LVM layout.
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then sudo(){ "$@"; }; fi
say(){ printf '%s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
die(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }
root_fstype(){ findmnt -n -o FSTYPE / 2>/dev/null || true; }
root_source(){ findmnt -n -o SOURCE / 2>/dev/null || true; }

backend(){
 if have timeshift; then printf 'timeshift'; return 0; fi
 if have snapper; then printf 'snapper'; return 0; fi
 if have zfs && [[ $(root_fstype) == zfs ]]; then printf 'zfs'; return 0; fi
 if have btrfs && [[ $(root_fstype) == btrfs ]]; then printf 'btrfs'; return 0; fi
 return 1
}

cmd_status(){
 local b; b="$(backend || true)"
 say "Root filesystem : $(root_source) ($(root_fstype))"
 say "Backend         : ${b:-none}"
 if [[ -z $b ]]; then
  say 'No snapshot backend detected.'
  say 'Install timeshift/snapper or use btrfs/ZFS to enable pre-update snapshots.'
 fi
}

create_snapshot(){
 local reason="${1:-manual}" yes="${2:-0}" b source stamp rc=0
 b="$(backend)" || { warn 'No snapshot backend available; skipping'; return 1; }
 stamp="$(date +%Y%m%d-%H%M%S)"
 if [[ $yes != 1 ]]; then
  [[ -t 0 ]] || { warn 'Snapshot needs a TTY (or --yes)'; return 1; }
  printf 'Create a %s snapshot before "%s"? Type SNAPSHOT: ' "$b" "$reason"
  local answer; read -r answer
  [[ $answer == SNAPSHOT ]] || { say 'Cancelled'; return 1; }
 fi
 case "$b" in
  timeshift)
   sudo timeshift --create --comments "NIRUPI: $reason" --scripted || rc=$?;;
  snapper)
   sudo snapper create --description "NIRUPI: $reason" --type pre || rc=$?;;
  zfs)
   source="$(root_source)"
   [[ -n $source ]] || { warn 'Could not determine the ZFS root dataset'; return 1; }
   sudo zfs snapshot "$source@nirupi-$stamp" || rc=$?;;
  btrfs)
   [[ -d /.snapshots && -w /.snapshots ]] || { warn '/.snapshots is not writable; create a snapper/timeshift config first'; return 1; }
   sudo btrfs subvolume snapshot -r / "/.snapshots/nirupi-$stamp" || rc=$?;;
 esac
 if (( rc == 0 )); then
  say "Snapshot created via $b ($reason)"
 else
  warn "Snapshot failed via $b"
 fi
 return "$rc"
}

cmd_list(){
 local b; b="$(backend || true)"
 case "$b" in
  timeshift) timeshift --list 2>/dev/null || true;;
  snapper) sudo snapper list 2>/dev/null || true;;
  zfs) zfs list -t snapshot -o name,creation 2>/dev/null | grep 'nirupi-' || true;;
  btrfs) [[ -d /.snapshots ]] && find /.snapshots -maxdepth 1 -mindepth 1 -type d -name 'nirupi-*' -printf '%f\n' 2>/dev/null || true;;
  *) say 'No snapshot backend available';;
 esac
}

case "${1:-status}" in
 status) cmd_status;;
 create)
  shift || true
  reason="manual"; yes=0
  while (($#)); do
   case "$1" in --yes) yes=1;; *) reason="$1";; esac
   shift
  done
  create_snapshot "$reason" "$yes";;
 list) cmd_list;;
 -h|--help) sed -n '1,18p' "$0";;
 *) die 'Usage: nirupi snapshot [status|create [REASON] [--yes]|list]';;
esac
