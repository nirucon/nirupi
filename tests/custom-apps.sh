#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" XDG_STATE_HOME="$TMP/home/.local/state"
mkdir -p "$HOME/.config/nirupi"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/apps.sh"

# No file -> non-interactive no-op.
PKGS=(base); DISTRO=arch
load_custom_packages
[[ " ${PKGS[*]} " == ' base ' ]]
custom_apps_status | grep -q 'not present'

cat > "$HOME/.config/nirupi/apps.conf" <<'EOF'
# extra packages
package=htop
package-debian=debian-only
package-arch=neofetch
repo=https://github.com/user/repo.git|~/Git/repo|make
EOF

PKGS=(base); DISTRO=arch
load_custom_packages
[[ " ${PKGS[*]} " == *' htop '* ]]
[[ " ${PKGS[*]} " == *' neofetch '* ]]
[[ " ${PKGS[*]} " != *' debian-only '* ]]
# Deduplication
PKGS=(base htop); load_custom_packages
[[ ${#PKGS[@]} -eq 3 ]]

PKGS=(base); DISTRO=debian
load_custom_packages
[[ " ${PKGS[*]} " == *' debian-only '* && " ${PKGS[*]} " != *' neofetch '* ]]

# Malformed package names are rejected, not injected.
PKGS=(base); DISTRO=arch
printf 'package=bad;rm -rf /\n' >> "$HOME/.config/nirupi/apps.conf"
load_custom_packages
[[ " ${PKGS[*]} " != *'bad'* ]]

self="$ROOT/tests/custom-apps.sh"
grep -Eq 'load_custom_packages' "$ROOT/install.sh"
grep -Eq 'install_custom_repos' "$ROOT/install.sh"
[[ -f "$self" ]]
echo 'PASS: custom_apps.conf parsing, per-distro packages and injection guard'
