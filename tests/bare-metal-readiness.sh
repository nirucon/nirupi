#!/usr/bin/env bash
# Local read-only host readiness report for Debian/Arch/CachyOS/Void.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo '=== NIRUPI BARE-METAL READINESS ==='
cat /etc/os-release | grep -E '^(PRETTY_NAME|ID|VERSION_ID)=' || :
printf 'Architecture: '; uname -m
printf 'User: '; id -un
printf 'Session: %s / display=%s\n' "${XDG_SESSION_TYPE:-unset}" "${DISPLAY:-unset}"
for tool in bash make cc pkg-config git Xorg startx sddm fish kitty fc-match; do
 if command -v "$tool" >/dev/null 2>&1; then printf 'OK      %s\n' "$tool"; else printf 'MISSING %s\n' "$tool"; fi
done
if command -v systemctl >/dev/null 2>&1; then
 for dm in sddm gdm3 gdm lightdm lxdm; do
  printf 'DM %-10s %s\n' "$dm" "$(systemctl is-enabled "$dm.service" 2>/dev/null || :)"
 done
fi
for f in "$HOME/.xinitrc" "$HOME/.Xresources" "$HOME/.config/suckless/dwm/config.h"; do
 if [[ -e $f || -L $f ]]; then printf 'EXISTS %s\n' "$f"; fi
done
for tool in dwm dmenu st slock; do
 path="$(command -v "$tool" 2>/dev/null || :)"
 printf 'BINARY %-6s %s\n' "$tool" "${path:-missing}"
done
printf '\nRead-only report. No packages or files modified.\n'
