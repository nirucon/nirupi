#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/lib/packages.sh"
DISTRO=void SESSION=sddm
packages
[[ " ${PKGS[*]} " == *' fish-shell '* ]]
[[ " ${PKGS[*]} " != *' fish '* ]]
[[ ${#PKGS[@]} == 38 ]]
DISTRO=debian; packages
[[ " ${PKGS[*]} " == *' fish '* ]]
[[ " ${PKGS[*]} " != *' fish-shell '* ]]
DISTRO=arch; packages
[[ " ${PKGS[*]} " == *' fish '* ]]
grep -q 'void_packages_preflight' "$ROOT/install.sh"
grep -q 'void_packages_preflight' "$ROOT/lib/packages.sh"
grep -q 'version|--version|-V' "$ROOT/runtime/nirupi"
[[ "$(cat "$ROOT/VERSION")" == 0.2.0-beta.5 ]]
echo 'PASS: beta.5 Void package mapping, preflight and version CLI; Debian/Arch preserved'
