#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/lib/packages.sh"
DISTRO=void SESSION=sddm
packages
[[ " ${PKGS[*]} " == *' fish-shell '* ]]
[[ " ${PKGS[*]} " != *' fish '* ]]
[[ ${#PKGS[@]} -ge 38 ]]
DISTRO=debian; packages
[[ " ${PKGS[*]} " == *' fish '* ]]
[[ " ${PKGS[*]} " != *' fish-shell '* ]]
DISTRO=arch; packages
[[ " ${PKGS[*]} " == *' fish '* ]]
grep -q 'void_packages_preflight' "$ROOT/install.sh"
grep -q 'void_packages_preflight' "$ROOT/lib/packages.sh"
grep -q 'version|--version|-V' "$ROOT/runtime/nirupi"
grep -Eq '^0\.4\.[0-9]+(-beta\.[0-9]+)?$' "$ROOT/VERSION"
echo 'PASS: beta.5 Void package mapping, preflight and version CLI; Debian/Arch preserved'
