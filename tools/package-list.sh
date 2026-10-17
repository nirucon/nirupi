#!/usr/bin/env bash
# Print package names for a target distro without requiring that distro.
#   tools/package-list.sh DISTRO [base|optional|hardware|all] [startx|sddm]
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DISTRO="${1:?usage: package-list.sh DISTRO [base|optional|hardware|all] [session]}"
MODE="${2:-base}"
SESSION="${3:-startx}"
warn(){ :; }
log(){ :; }
die(){ printf '%s\n' "$*" >&2; exit 1; }
source "$ROOT/lib/packages.sh"
valid_profile "${NIRUPI_PROFILE:-desktop}" || NIRUPI_PROFILE=desktop
packages
case "$MODE" in
 base) printf '%s\n' "${PKGS[@]}";;
 optional) printf '%s\n' "${OPTIONAL_PKGS[@]}";;
 hardware) printf '%s\n' "${HW_PKGS[@]}";;
 all) printf '%s\n' "${PKGS[@]}" "${OPTIONAL_PKGS[@]}" "${HW_PKGS[@]}";;
 *) die 'mode must be base, optional, hardware or all';;
esac
