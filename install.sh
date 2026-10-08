#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
source "$ROOT/lib/packages.sh"
source "$ROOT/lib/managed.sh"
source "$ROOT/lib/install.sh"
source "$ROOT/lib/release.sh"
SESSION=sddm; ACTION=plan
usage(){ cat <<'EOF'
NIRUPI 0.2.0-beta.4
Usage: ./install.sh [--plan|--apply|--doctor|--audit|--verify|--history|--rollback] [--session sddm|startx]
Default --plan never modifies files. --apply requires confirmation.
EOF
}
while (($#)); do
 case "$1" in
 --plan) ACTION=plan;; --apply) ACTION=apply;; --doctor) ACTION=doctor;; --audit) ACTION=audit;; --verify) ACTION=verify;; --history) ACTION=history;; --rollback) ACTION=rollback;;
 --session) shift; (($#)) || die 'Missing --session value'; SESSION=$1;;
 -h|--help) usage; exit 0;; *) die "Unknown argument: $1";; esac
 shift
done
[[ $SESSION == sddm || $SESSION == startx ]] || die 'Invalid session'
if [[ $ACTION == verify ]]; then exec "$ROOT/tests/post-install-verify.sh"; fi
if [[ $ACTION == history ]]; then release_history; exit 0; fi
if [[ $ACTION == rollback ]]; then release_rollback; exit 0; fi
packages
printf '\nN I R U P I   /   N O I R   %s\nDistribution: %s\nSession: %s\nAction: %s\n\n' "$VERSION" "$DISTRO" "$SESSION" "$ACTION"
if [[ $ACTION == audit ]]; then
  exec "$ROOT/tests/hardware-audit.sh"
fi
if [[ $ACTION == doctor ]]; then
 if command -v fc-match >/dev/null 2>&1; then
  resolved="$(fc-match -f '%{family}' 'JetBrainsMono Nerd Font' 2>/dev/null || :)"
  if [[ $resolved == *'JetBrainsMono Nerd Font'* || $resolved == *'JetBrainsMono NFM'* ]]; then
   printf ' OK  JetBrainsMono Nerd Font (%s)\n' "$resolved"
  else
   printf ' --  JetBrainsMono Nerd Font not confirmed; fontconfig fallback: %s\n' "${resolved:-unknown}"
  fi
 else
  printf ' --  fc-match unavailable; cannot verify preferred font\n'
 fi
 for cmd in bash sudo make cc git pkg-config Xorg startx sddm kitty feh xsetroot setxkbmap gawk fzf rofi alacritty pcmanfm playerctl brightnessctl wpctl; do
  if command -v "$cmd" >/dev/null 2>&1; then printf ' OK  %s\n' "$cmd"; else printf ' --  %s\n' "$cmd"; fi
 done
 printf '\nDWM shortcut dependencies (optional items are not auto-installed):\n'
 for cmd in maim xclip notify-send flameshot sxiv gimp slock; do
  if command -v "$cmd" >/dev/null 2>&1; then printf ' OK  %s\n' "$cmd"; else printf ' --  %s (shortcut may not work)\n' "$cmd"; fi
 done
 [[ $SESSION == startx ]] && warn 'Existing ~/.xinitrc is preserved and may need manual configuration'
 exit 0
fi
printf 'Login manager: %s (custom theme requested when SDDM is selected)\n' "$SESSION"
printf 'Packages (%s):\n  %s\n\n' "${#PKGS[@]}" "${PKGS[*]}"
printf 'Bundled desktop helpers: status, wallpaper, keybindings, screenshots, clipboard and webapp launchers.\n'
printf 'Appearance: new profiles get Adwaita-dark; existing GTK settings are preserved.\n'
printf 'Browser: Super+B uses a configurable launcher on new DWM configs; existing DWM configs are preserved.\n'
printf 'Changes: package installation, build patched DWM/dmenu/st/slock, deploy user config, register X11 session.\n'
printf 'Important: packages are not distro-verified; old shell/config may need migration.\n'
printf 'NIRU Noir: the bundled Rofi theme will be installed if absent; existing themes are preserved.\n'

if [[ $SESSION == sddm ]]; then printf 'SDDM: installing system theme and enabling service requires separate confirmation.\n'; fi
printf 'Slock: optional setuid-root installation requires separate confirmation.\n'
printf 'Backups cover user file replacements, not system-wide rollback. Arch/CachyOS requires an explicitly approved full upgrade.\n'
if [[ $ACTION == plan ]]; then log 'Read-only plan complete'; exit 0; fi
require sudo; require mktemp; require install; require cp; require mv; require readlink; require cmp; require find; require nproc; require tar; require sha256sum; require awk; require cut; require tail
# Never install over a live graphical login or remotely during the first alpha tests.
[[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] || die 'Run --apply from a local TTY, not from a graphical session'
[[ -d /usr/share/xsessions ]] || warn 'X11 sessions directory absent; will create after package installation'
# Refuse to continue if another package manager holds a lock.
if [[ $DISTRO == debian ]] && command -v fuser >/dev/null 2>&1 && fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then die 'dpkg is busy'; fi
[[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || die 'Hyprland active; use a disposable X11 VM for first installation'
[[ -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] || die 'Remote interactive installation over SSH refused'
# A TTY is required so system-level changes cannot be triggered by a headless pipeline.
[[ -t 0 ]] || die '--apply requires an interactive terminal'
printf '\nType INSTALL to proceed: '; read -r confirm
[[ $confirm == INSTALL ]] || die 'Cancelled'
# Validate all bundled inputs before touching the package manager.
"$ROOT/tests/preflight.sh" --assets || die 'Bundled asset preflight failed'
# Reject system-level session conflicts before package installation or user changes.
# The same checks run again during deployment to guard against races.
check_system_session_conflicts
check_display_manager_conflicts
check_home_path_safety
check_user_install_conflicts
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
release_snapshot "$RUN_ID"
BACKUP_DIR="$STATE/backups/$RUN_ID"
mkdir -p "$BACKUP_DIR"
log "Backup directory: $BACKUP_DIR"
# Ensure the requested build prerequisites are present in the package transaction.
install_packages
require make; require cc; require pkg-config
install_desktop
"$ROOT/tests/post-install-verify.sh" || warn "Post-install verification found missing components; inspect before reboot"
log 'Beta installation finished. Verify graphical login before reboot; rollback restores NIRUPI binary links only, not system changes.'
