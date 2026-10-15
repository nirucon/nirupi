#!/usr/bin/env bash
# Clean-install coverage: essential packages on all distros, Arch AUR-helper,
# service enabling and doctor hints.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/lib/packages.sh"; INS="$ROOT/lib/install.sh"; RUN="$ROOT/runtime/nirupi"

for p in xf86-input-libinput xserver-xorg-input-libinput mesa-dri libgl1-mesa-dri \
         sof-firmware alsa-ucm-conf alsa-pipewire pipewire-alsa \
         man-db bash-completion xdg-desktop-portal xdg-desktop-portal-gtk; do
  grep -q "$p" "$PKG" || { echo "FAIL package missing in packages.sh: $p" >&2; exit 1; }
done

grep -q 'detect_hardware_packages' "$PKG" || { echo 'FAIL hardware detection missing' >&2; exit 1; }
grep -q 'archlinux-keyring' "$PKG" || { echo 'FAIL keyring pre-step missing' >&2; exit 1; }
grep -q 'void-repo-nonfree' "$PKG" || { echo 'FAIL void nonfree repo missing' >&2; exit 1; }

grep -q 'ensure_aur_helper' "$INS" || { echo 'FAIL ensure_aur_helper missing' >&2; exit 1; }
grep -q 'paru-bin' "$INS" || { echo 'FAIL paru-bin missing' >&2; exit 1; }
grep -q 'yay-bin' "$INS" || { echo 'FAIL yay-bin fallback missing' >&2; exit 1; }
grep -q 'enable_services' "$INS" || { echo 'FAIL enable_services missing' >&2; exit 1; }
grep -q 'tailscaled' "$INS" || { echo 'FAIL tailscaled enable missing' >&2; exit 1; }

grep -q '^ensure_aur_helper$' "$ROOT/install.sh" || { echo 'FAIL ensure_aur_helper not called' >&2; exit 1; }
grep -q '^enable_services$' "$ROOT/install.sh" || { echo 'FAIL enable_services not called' >&2; exit 1; }

grep -q 'AUR helper' "$RUN" || { echo 'FAIL doctor AUR hint missing' >&2; exit 1; }
grep -q 'tailscaled' "$RUN" || { echo 'FAIL doctor tailscale hint missing' >&2; exit 1; }

echo 'PASS: clean-install package coverage, AUR helper, service enabling and doctor hints'
