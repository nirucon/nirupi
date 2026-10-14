#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
source "$ROOT/lib/packages.sh"
source "$ROOT/lib/managed.sh"
source "$ROOT/lib/migrate.sh"
source "$ROOT/lib/theme.sh"
source "$ROOT/lib/apps.sh"
source "$ROOT/lib/install.sh"
source "$ROOT/lib/release.sh"
source "$ROOT/lib/rollback.sh"
SESSION=sddm; ACTION=plan; DRY_RUN=0; REFRESH=0; ADOPT=0
usage(){ printf 'NIRUPI %s\n' "$VERSION"; cat <<'EOF'
Usage: ./install.sh [action] [--session sddm|startx]
Actions:
  --plan            Read-only plan (default); never modifies files.
  --apply           Install/upgrade (requires local TTY + confirmation).
  --doctor          Diagnose fonts, tools and installed artifacts.
  --audit           Read-only hardware/distro audit.
  --verify          Verify installed binary links and configs.
  --history         List binary rollback snapshots.
  --rollback        Restore NIRUPI binary links (local TTY only).
  --migrate         Show the migration report for this system.
  --diff            Show migration + theme diff without changing files.
  --theme-only      Re-apply the NIRU Noir theme only.
  --update-dots     Update NIRUPI-managed dotfiles only.
Options:
  --session sddm|startx   Login manager target (default sddm).
  --dry-run               Combine with --apply to preview without writing.
  --refresh               Adopt the bundled NIRUPI scripts even if untracked (backup kept).
  --adopt-dots            Force-adopt bundled dotfiles + dwm config (backup kept).
  -h, --help              Show this help.
EOF
}
while (($#)); do
 case "$1" in
 --plan) ACTION=plan;; --apply) ACTION=apply;; --doctor) ACTION=doctor;; --audit) ACTION=audit;; --verify) ACTION=verify;; --history) ACTION=history;; --rollback) ACTION=rollback;;
 --migrate) ACTION=migrate;; --diff) ACTION=diff;; --theme-only) ACTION=theme;; --update-dots) ACTION=dots;; --adopt-dots) ACTION=dots; ADOPT=1;;
 --dry-run) DRY_RUN=1;; --refresh) REFRESH=1;;
 --session) shift; (($#)) || die 'Missing --session value'; SESSION=$1;;
 -h|--help) usage; exit 0;; *) die "Unknown argument: $1";; esac
 shift
done
[[ $SESSION == sddm || $SESSION == startx ]] || die 'Invalid session'
if [[ $ACTION == verify ]]; then exec "$ROOT/tests/post-install-verify.sh"; fi
if [[ $ACTION == history ]]; then release_history; exit 0; fi
if [[ $ACTION == rollback ]]; then release_rollback; exit 0; fi
packages
# Optional per-user extra packages/repos; absence is not an error.
load_custom_packages
printf '\nN I R U P I   /   N O I R   %s\nDistribution: %s\nSession: %s\nAction: %s\n\n' "$VERSION" "$DISTRO" "$SESSION" "$ACTION"
if [[ $ACTION == audit ]]; then
  exec "$ROOT/tests/hardware-audit.sh"
fi
if [[ $ACTION == migrate || $ACTION == diff ]]; then
  migration_report
  [[ $ACTION == diff ]] || exit 0
  theme_diff
  exit 0
fi
if [[ $ACTION == theme || $ACTION == dots ]]; then
  RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
  BACKUP_DIR="$STATE/backups/$RUN_ID"
  if [[ $DRY_RUN == 1 ]]; then
    theme_diff; exit 0
  fi
  require mktemp; require install; require cp; require mv; require sha256sum; require awk
  mkdir -p "$STATE" "$BACKUP_DIR"
  check_home_path_safety
  if [[ $ACTION == dots || $REFRESH == 1 ]]; then
   log 'Adopting bundled NIRUPI scripts (backups kept)'
   NIRUPI_REFRESH=1 install_helpers
  fi
  deploy_bundle
  if [[ $ADOPT == 1 ]]; then export NIRUPI_FORCE_CONFIGS=1; fi
  NIRUPI_NOIR_DIR="$ROOT/vendor/noir" theme_apply
  if [[ $ADOPT == 1 && -f $ROOT/vendor/suckless/dwm/config.h ]]; then
   NIRUPI_FORCE_CONFIGS=1 managed_config_install 'dwm/config.h' "$ROOT/vendor/suckless/dwm/config.h" "$HOME/.config/suckless/dwm/config.h"
   log 'Adopted the bundled dwm config.h (previous file backed up)'
  fi
  write_installed_state
  restart_statusbar_if_running
  exit 0
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
 for cmd in bash sudo make cc git pkg-config Xorg startx sddm kitty feh xsetroot setxkbmap gawk fzf rofi alacritty pcmanfm playerctl brightnessctl wpctl opencode slock xss-lock nextcloud; do
  if command -v "$cmd" >/dev/null 2>&1; then printf ' OK  %s\n' "$cmd"; else printf ' --  %s\n' "$cmd"; fi
 done
 printf '\nDWM shortcut dependencies (optional items are not auto-installed):\n'
 for cmd in maim xclip notify-send flameshot sxiv gimp slock; do
  if command -v "$cmd" >/dev/null 2>&1; then printf ' OK  %s\n' "$cmd"; else printf ' --  %s (shortcut may not work)\n' "$cmd"; fi
 done
 printf '\nNIRU Noir theme:\n'
 if [[ -x $HOME/.local/bin/nirupi-appearance ]]; then
  "$HOME/.local/bin/nirupi-appearance" status || :
 fi
 custom_apps_status
 [[ $SESSION == startx ]] && warn 'Existing ~/.xinitrc is preserved and may need manual configuration'
 exit 0
fi
printf 'Login manager: %s (custom theme requested when SDDM is selected)\n' "$SESSION"
printf 'Packages (%s):\n  %s\n\n' "${#PKGS[@]}" "${PKGS[*]}"
printf 'Bundled desktop helpers: status, wallpaper, keybindings, screenshots, clipboard and webapp launchers.\n'
printf 'Appearance: NIRU Noir dark theme applied across terminals, shells, TUI tools and browsers.\n'
printf 'Browser: Super+B uses a configurable launcher on new DWM configs; existing DWM configs are merged.\n'
printf 'Changes: package installation, build patched DWM/dmenu/st/slock, deploy user config, register X11 session.\n'
printf 'Migration: existing configs are merged (never deleted); foreign binaries are archived, not overwritten.\n'

if [[ $SESSION == sddm ]]; then printf 'SDDM: installing system theme and enabling service requires separate confirmation.\n'; fi
printf 'Slock: optional setuid-root installation requires separate confirmation.\n'
printf 'Backups cover user file replacements, not system-wide rollback. Arch/CachyOS requires an explicitly approved full upgrade.\n'
if [[ $ACTION == plan ]]; then log 'Read-only plan complete'; exit 0; fi
if [[ $DRY_RUN == 1 ]]; then migration_report; theme_diff; log 'Dry run complete; no changes made'; exit 0; fi
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
check_system_session_conflicts
check_display_manager_conflicts
check_home_path_safety
check_user_install_conflicts
void_packages_preflight
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
release_snapshot "$RUN_ID"
BACKUP_DIR="$STATE/backups/$RUN_ID"
mkdir -p "$BACKUP_DIR"
log "Backup directory: $BACKUP_DIR"
# Ensure the requested build prerequisites are present in the package transaction.
install_packages
install_optional_packages
install_custom_packages
install_custom_repos
require make; require cc; require pkg-config
ensure_nerd_font
install_opencode
export NIRUPI_REFRESH=$REFRESH
install_desktop
write_installed_state
"$ROOT/tests/post-install-verify.sh" || warn "Post-install verification found missing components; inspect before reboot"
log 'Installation finished. Verify graphical login before reboot; rollback restores NIRUPI links and configs, not system packages.'
