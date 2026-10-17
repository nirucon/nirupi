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
PROFILE="${NIRUPI_PROFILE:-desktop}"
NIRUPI_INSTALL_OPTIONAL="${NIRUPI_INSTALL_OPTIONAL:-0}"
NIRUPI_FULL_UPGRADE="${NIRUPI_FULL_UPGRADE:-ask}"
PROFILE_SET=0; SESSION_SET=0; OPTIONAL_SET=0
usage(){ printf 'NIRUPI %s\n' "$VERSION"; cat <<'EOF'
Usage: ./install.sh [action] [--session sddm|startx] [--profile minimal|desktop|full]
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
  --profile NAME          minimal, desktop (default) or full.
  --optional              Install the optional application set.
  --no-optional           Skip optional applications (default).
  --full-upgrade          Allow a full synchronized system upgrade on Void.
  --no-full-upgrade       Install only the requested packages on Void.
  --dry-run               Combine with --apply to preview without writing.
  --refresh               Adopt the bundled NIRUPI scripts even if untracked (backup kept).
  --adopt-dots            Force-adopt bundled dotfiles + dwm config (backup kept).
  -h, --help              Show this help.
EOF
}
# Optional whiptail installer TUI. Silently skipped when whiptail is absent or
# stdin is not a TTY; cancelling an interactive apply aborts before any change.
installer_tui(){
  [[ ${NIRUPI_NO_TUI:-0} == 1 ]] && return 0
  command -v whiptail >/dev/null 2>&1 || return 0
  [[ -t 0 ]] || return 0
  local choice opt_text
  whiptail --title "NIRUPI $VERSION" --backtitle 'NIRU Noir desktop' \
    --msgbox "Distribution: $DISTRO\nSession: $SESSION\n\nThis installer builds dwm, dmenu, st and slock into ~/.local, deploys the theme and helpers, and can install system packages after an explicit confirmation.\n\nNothing is changed until you type INSTALL at the end." 16 78 || return 1
  if (( ! PROFILE_SET )); then
    choice="$(whiptail --title 'Install profile' --backtitle 'NIRU Noir desktop' --default-item "$PROFILE" --menu 'Choose how much to install:' 17 78 3 \
        minimal 'Desktop, status bar, audio and network only' \
        desktop 'NIRUPI desktop (recommended)' \
        full    'Desktop plus the optional application set' 3>&1 1>&2 2>&3)" || return 1
    case "$choice" in minimal|desktop|full) PROFILE="$choice";; esac
  fi
  if (( ! SESSION_SET )); then
    choice="$(whiptail --title 'Login session' --backtitle 'NIRU Noir desktop' --default-item "$SESSION" --menu 'How should the desktop start?' 16 78 2 \
        startx 'Minimal X session from a text TTY (.xinitrc)' \
        sddm   'Use the SDDM display manager (theme provided)' 3>&1 1>&2 2>&3)" || return 1
    case "$choice" in startx|sddm) SESSION="$choice";; esac
  fi
  if [[ $PROFILE == full ]]; then
    NIRUPI_INSTALL_OPTIONAL=1
  elif (( ! OPTIONAL_SET )); then
    if whiptail --title 'Optional applications' --backtitle 'NIRU Noir desktop' --yesno \
        'Install optional applications (image editor, media players, extra tools)?' 10 78; then
      NIRUPI_INSTALL_OPTIONAL=1
    else
      NIRUPI_INSTALL_OPTIONAL=0
    fi
  fi
  [[ $NIRUPI_INSTALL_OPTIONAL == 1 ]] && opt_text='yes' || opt_text='no'
  whiptail --title 'Ready to install' --backtitle 'NIRU Noir desktop' --yesno \
    "Profile:  $PROFILE\nSession:  $SESSION\nOptional: $opt_text\nTheme:    NIRU Noir (change later with Super+Ctrl+T)\n\nContinue to the typed INSTALL confirmation?" 14 78 || return 1
  return 0
}
while (($#)); do
 case "$1" in
 --plan) ACTION=plan;; --apply) ACTION=apply;; --doctor) ACTION=doctor;; --audit) ACTION=audit;; --verify) ACTION=verify;; --history) ACTION=history;; --rollback) ACTION=rollback;;
 --migrate) ACTION=migrate;; --diff) ACTION=diff;; --theme-only) ACTION=theme;; --update-dots) ACTION=dots;; --adopt-dots) ACTION=dots; ADOPT=1;;
 --dry-run) DRY_RUN=1;; --refresh) REFRESH=1;;
 --session) shift; (($#)) || die 'Missing --session value'; SESSION=$1; SESSION_SET=1;;
 --profile) shift; (($#)) || die 'Missing --profile value'; PROFILE=$1; PROFILE_SET=1;;
 --optional) NIRUPI_INSTALL_OPTIONAL=1; OPTIONAL_SET=1;;
 --no-optional) NIRUPI_INSTALL_OPTIONAL=0; OPTIONAL_SET=1;;
 --full-upgrade) NIRUPI_FULL_UPGRADE=1;;
 --no-full-upgrade) NIRUPI_FULL_UPGRADE=0;;
 -h|--help) usage; exit 0;; *) die "Unknown argument: $1";; esac
 shift
done
[[ $SESSION == sddm || $SESSION == startx ]] || die 'Invalid session'
valid_profile "$PROFILE" || die "Invalid profile: $PROFILE (use minimal, desktop or full)"
[[ $PROFILE == full ]] && NIRUPI_INSTALL_OPTIONAL=1
export NIRUPI_PROFILE="$PROFILE" NIRUPI_INSTALL_OPTIONAL NIRUPI_FULL_UPGRADE
# Optional interactive TUI (profile, session target, optional packages). Non-fatal.
if [[ $ACTION == apply ]]; then installer_tui || die 'Cancelled'; export NIRUPI_PROFILE="$PROFILE" NIRUPI_INSTALL_OPTIONAL; fi
if [[ $ACTION == verify ]]; then exec "$ROOT/tests/post-install-verify.sh"; fi
if [[ $ACTION == history ]]; then release_history; exit 0; fi
if [[ $ACTION == rollback ]]; then release_rollback; exit 0; fi
packages
# Optional per-user extra packages/repos; absence is not an error.
load_custom_packages
printf '\nN I R U P I   /   N O I R   %s\nDistribution: %s\nSession: %s\nProfile: %s\nAction: %s\n\n' "$VERSION" "$DISTRO" "$SESSION" "$NIRUPI_PROFILE" "$ACTION"
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
 for cmd in bash sudo make cc git pkg-config Xorg startx sddm kitty feh xsetroot setxkbmap gawk fzf rofi alacritty pcmanfm playerctl brightnessctl wpctl opencode slock xss-lock nextcloud xinput ffmpeg gpg; do
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
printf 'Base packages (%s):\n  %s\n\n' "${#PKGS[@]}" "${PKGS[*]}"
if [[ ${NIRUPI_INSTALL_OPTIONAL:-0} == 1 || $NIRUPI_PROFILE == full ]]; then
  printf 'Optional applications (%s):\n  %s\n\n' "${#OPTIONAL_PKGS[@]}" "${OPTIONAL_PKGS[*]}"
else
  printf 'Optional applications: skipped (use --optional or --profile full)\n\n'
fi
if ((${#HW_PKGS[@]})); then
  printf 'Hardware packages (%s, best effort):\n  %s\n\n' "${#HW_PKGS[@]}" "${HW_PKGS[*]}"
fi
printf 'Bundled desktop helpers: status, wallpaper, keybindings, screenshots, clipboard and webapp launchers.\n'
printf 'Appearance: NIRU Noir dark theme applied across terminals, shells, TUI tools and browsers.\n'
printf 'Browser: Super+B uses a configurable launcher on new DWM configs; existing DWM configs are merged.\n'
printf 'Changes: package installation, build patched DWM/dmenu/st/slock, deploy user config, register X11 session.\n'
printf 'Migration: existing configs are merged (never deleted); foreign binaries are archived, not overwritten.\n'
printf 'Rollback: nirupi rollback --all (configs + binary links); package rollback is distro-native.\n'

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
ensure_aur_helper
require make; require cc; require pkg-config
ensure_nerd_font
install_opencode
export NIRUPI_REFRESH=$REFRESH
install_desktop
enable_services
ensure_nirupi_session
write_installed_state
"$ROOT/tests/post-install-verify.sh" || warn "Post-install verification found missing components; inspect before reboot"
log 'Installation finished. Verify graphical login before reboot; rollback restores NIRUPI links and configs, not system packages.'
