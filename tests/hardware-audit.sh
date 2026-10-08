#!/usr/bin/env bash
# Read-only pre-hardware report; never changes system state.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
printf 'NIRUPI %s — hardware audit (read-only)\n' "$(<"$ROOT/VERSION")"
printf 'OS: '; grep '^PRETTY_NAME=' /etc/os-release || :
printf 'Architecture: '; uname -m
printf 'Kernel: '; uname -r
printf 'Init: '; if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then echo systemd; elif command -v sv >/dev/null 2>&1; then echo runit; else echo unknown; fi
printf 'Session: DISPLAY=%s WAYLAND_DISPLAY=%s\n' "${DISPLAY:-unset}" "${WAYLAND_DISPLAY:-unset}"
printf 'User: %s (uid %s)\n' "${USER:-unknown}" "$(id -u)"
for cmd in sudo git make cc pkg-config Xorg startx sddm feh xsetroot setxkbmap slock loginctl zzz; do
 if command -v "$cmd" >/dev/null 2>&1; then printf 'OK   %s\n' "$cmd"; else printf 'MISS %s\n' "$cmd"; fi
done
for path in "$HOME/.xinitrc" "$HOME/.Xresources" "$HOME/.config/fish/config.fish" /usr/share/xsessions/nirupi-dwm.desktop /etc/sddm.conf.d/10-niru-noir.conf; do
 [[ ! -e "$path" && ! -L "$path" ]] || printf 'EXISTS %s (preservation/merge review needed)\n' "$path"
done
printf 'Available disk space in HOME (KiB): '; df -Pk "$HOME" | awk 'NR==2{print $4}'
printf 'NOTE: report does not prove package resolution, build success, graphical login, or suspend safety.\n'
