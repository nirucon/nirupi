#!/usr/bin/env bash
check_system_session_conflicts(){
 local launcher="${NIRUPI_SYSTEM_LAUNCHER:-/usr/local/bin/nirupi-session}"
 local desktop="${NIRUPI_SYSTEM_DESKTOP:-/usr/share/xsessions/nirupi-dwm.desktop}"
 if [[ -e $launcher || -L $launcher ]]; then
   [[ -f $launcher && ! -L $launcher ]] ||
     die "Existing system session launcher is not a regular file: $launcher"
   # Accept any launcher that runs the user's session script: quoting style,
   # a trailing "$@" or comments must not break the check. Only a launcher that
   # does something else entirely is refused.
   grep -Fq '.local/bin/nirupi-session' "$launcher" ||
     die "Existing $launcher does not run ~/.local/bin/nirupi-session; move it aside and retry"
 fi
 if [[ -e $desktop || -L $desktop ]]; then
   [[ -f $desktop && ! -L $desktop ]] ||
     die "Existing desktop session entry is not a regular file: $desktop"
   grep -Fq 'nirupi-session' "$desktop" ||
     die "Existing $desktop does not start nirupi-session; move it aside and retry"
 fi
}
# Fail before package transactions if enabling SDDM would conflict with another DM.
check_display_manager_conflicts() {
 [[ ${SESSION:-startx} == sddm ]] || return 0
 local dm
 if [[ $DISTRO == void ]]; then
  # Void uses runit: an enabled service is a symlink under /var/service (which
  # itself points at /run/runit/runsvdir/current). No systemctl is involved.
  for dm in gdm lightdm lxdm; do
   if [[ -e /var/service/$dm || -e /run/runit/service/$dm ]]; then
    die "Existing enabled display manager: $dm; select --session startx or disable it explicitly"; return 1
   fi
  done
  return 0
 fi
 command -v systemctl >/dev/null 2>&1 || return 0
 for dm in gdm lightdm lxdm; do
  if systemctl is-enabled --quiet "$dm.service" 2>/dev/null; then
   die "Existing enabled display manager: $dm.service; select --session startx or disable it explicitly"; return 1
  fi
 done
}
# All write targets under HOME must be real directories, never followed through
# a user-created symlink (including the state directory).
check_home_path_safety() {
 local path
 for path in "$HOME/.local" "$HOME/.local/bin" "$HOME/.local/lib" \
             "$HOME/.local/lib/nirupi" "$HOME/.config" \
             "$HOME/.config/suckless" "$HOME/.config/suckless/dwm" \
             "$HOME/.local/share" "$HOME/.local/share/rofi" \
             "$HOME/.local/share/rofi/themes" \
             "${XDG_STATE_HOME:-$HOME/.local/state}" "$STATE"; do
  if [[ -L $path || ( -e $path && ! -d $path ) ]]; then
   die "Unsafe NIRUPI directory path: $path"; return 1
  fi
 done
}
# Numeric schema version from a dwm config.h (0 when the marker is absent).
dwm_config_version() {
 local v
 v="$(sed -n 's/^#define NIRUPI_CONFIG_VERSION[[:space:]]\{1,\}\([0-9]\{1,\}\).*/\1/p' "$1" 2>/dev/null | head -n1)"
 printf '%s' "${v:-0}"
}
# True when the user's config.h is a safe build input for the bundled dwm:
# a regular file whose schema version is at least the bundled one. An older
# schema is preserved (and proposed as config.h.nirupi-new) but must not be
# compiled, because dwm.c rejects it at compile time.
dwm_config_current() {
 local user="$1" bundled="$2" uv bv
 [[ -f $user && ! -L $user ]] || return 1
 uv="$(dwm_config_version "$user")"; bv="$(dwm_config_version "$bundled")"
 [[ $uv != 0 && $uv -ge $bv ]]
}
# Choose the effective DWM config BEFORE compiling, without modifying source or HOME.
# The user's regular config takes precedence, even when customized. A symlink or
# unexpected file type is never read as build input.
select_dwm_build_config() {
 local bundled="$1" custom="$2" staged="$3"
 [[ -f $bundled && ! -L $bundled ]] || die "Bundled DWM config is missing or unsafe: $bundled"
 if [[ -e $custom || -L $custom ]]; then
  if [[ -L $custom || ! -f $custom ]]; then
   die "Unsafe DWM configuration path: $custom"
  fi
  log "Building DWM with existing user config: $custom"
  cp -- "$custom" "$staged"
 else
  log 'Building DWM with bundled NIRU Noir config'
  cp -- "$bundled" "$staged"
 fi
}
# Preflight all known local collisions before any package-manager transaction.
# Keep this read-only: do not create directories or modify existing files.
check_user_install_conflicts() {
  local app path target custom="$HOME/.config/suckless/dwm/config.h"
  # Foreign binaries/symlinks are no longer fatal: an explicit --apply archives
  # them under ~/.local/state/nirupi/legacy/ before linking (see lib/migrate.sh).
  for app in dwm dmenu st dmenu_run dmenu_path stest slstatus; do
   path="$HOME/.local/bin/$app"
   if [[ -L $path ]]; then
    target="$(readlink -- "$path")"
    [[ $target == "$HOME/.local/lib/nirupi/"* ]] || warn "Legacy symlink will be archived: $path -> $target"
   elif [[ -e $path ]]; then
    [[ -f $path ]] || die "Unsafe executable path (not a regular file): $path"
    warn "Legacy executable will be archived: $path"
   fi
  done
 if [[ -e $custom || -L $custom ]]; then
  [[ -f $custom && ! -L $custom ]] || die "Unsafe DWM configuration path: $custom"
 fi
 for app in kitty fish dunst picom rofi alacritty gtk-3.0 cmus; do
  path="$HOME/.config/$app"
  if [[ -L $path ]]; then
   warn "Existing config symlink will be preserved: $path"
  elif [[ -e $path && ! -d $path ]]; then
   warn "Existing non-directory config path will be preserved: $path"
  fi
 done
 # Manifest symlinks are refused before installation can change any user file.
 for path in "$STATE/managed-helpers.tsv" "$STATE/managed-configs.tsv"; do
  [[ ! -L $path ]] || die "Unsafe manifest symlink: $path"
 done
}
restart_statusbar_if_running(){
 [[ ${NIRUPI_NO_RESTART:-0} == 1 ]] && return 0
 command -v pgrep >/dev/null 2>&1 || return 0
 local dp display xauth
 dp="$(pgrep -x dwm 2>/dev/null | head -n1 || true)"
 [[ -n $dp && -r /proc/$dp/environ ]] || return 0
 display="$(tr '\0' '\n' < "/proc/$dp/environ" 2>/dev/null | sed -n 's/^DISPLAY=//p' | head -n1 || true)"
 xauth="$(tr '\0' '\n' < "/proc/$dp/environ" 2>/dev/null | sed -n 's/^XAUTHORITY=//p' | head -n1 || true)"
 [[ -n $display ]] || return 0
 pkill -f '[d]wm-status.sh' 2>/dev/null || true
 # Drop the segment cache so identity/kernel/host segments refresh after an upgrade.
 rm -rf -- "${XDG_CACHE_HOME:-$HOME/.cache}/dwm-status"
 sleep 1
 setsid env DISPLAY="$display" ${xauth:+XAUTHORITY="$xauth"} "$HOME/.local/bin/dwm-status.sh" </dev/null >/dev/null 2>&1 &
 log 'Restarted the running status bar with the updated script'
}
install_helpers(){
 local app src dest updates_dest="$HOME/.local/bin/nirupi-updates"
 managed_helper_install nirupi-updates "$ROOT/runtime/nirupi-updates" "$updates_dest"
 managed_helper_install nirupi "$ROOT/runtime/nirupi" "$HOME/.local/bin/nirupi"
 managed_helper_install nirupi-appearance "$ROOT/runtime/nirupi-appearance" "$HOME/.local/bin/nirupi-appearance"
 managed_helper_install nirupi-browser "$ROOT/runtime/nirupi-browser" "$HOME/.local/bin/nirupi-browser"
 managed_helper_install nirupi-maintenance "$ROOT/runtime/nirupi-maintenance" "$HOME/.local/bin/nirupi-maintenance"
 managed_helper_install nirupi-gc "$ROOT/runtime/nirupi-gc.sh" "$HOME/.local/bin/nirupi-gc.sh"
 managed_helper_install nirupi-update "$ROOT/runtime/nirupi-update.sh" "$HOME/.local/bin/nirupi-update.sh"
 # Remove the legacy no-extension compatibility symlink: dwm now calls the .sh
 # helper directly (the old symlink is no longer needed).
 if [[ -L $HOME/.local/bin/nirupi-status-click ]]; then
  rm -f -- "$HOME/.local/bin/nirupi-status-click"
  log 'Removed legacy nirupi-status-click compatibility symlink'
 fi
 for app in dwm-status.sh wallrotate.sh wallpaperchange.sh sleep-suspend.sh dwm-keybindings.sh apply-screenlayout.sh clip-menu.sh clip-save.sh screenshot-browser.sh screenshot-select.sh sr-dmenu.sh tui-dmenu.sh webapp-ai-launcher.sh webapp-dmenu-brave.sh webapp-dmenu.sh nirupi-lock.sh nirupi-logout.sh nirupi-power.sh nirupi-nightlight.sh nirupi-webapp.sh nirupi-osd.sh nirupi-caffeine.sh nirupi-focus.sh nirupi-record.sh nirupi-window.sh nirupi-keyboard.sh nirupi-touchpad.sh nirupi-app.sh nirupi-clipd.sh nirupi-calendar.sh nirupi-calendar.py nirupi-sysupdate.sh nirupi-keys.sh nirupi-menu.sh nirupi-agent.sh nirupi-backup.sh nirupi-status-click.sh nirupi-emoji.sh nirupi-clip-transform.sh nirupi-audio.sh nirupi-capture.sh nirupi-agent-selection.sh nirupi-wallpaper.sh nirupi-tag-wallpaper.sh nirupi-reload.sh nirupi-edit.sh nirupi-ssh.sh nirupi-agent-ask.sh nirupi-agent-screen.sh nirupi-ask-command.sh nirupi-autostart.sh nirupi-battery.sh nirupi-notifications.sh nirupi-launch.sh nirupi-rofi-clip.sh nirupi-rofi-files.sh nirupi-agent-rewrite.sh nirupi-usb.sh nirupi-lid.sh nirupi-barmode.sh nirupi-updatecheck.sh nirupi-popup.sh nirupi-updates-popup.sh nirupi-battery-popup.sh nirupi-disk-popup.sh nirupi-weather-popup.sh nirupi-btop.sh nirupi-panel.py nirupi-changes.sh nirupi-fleet.sh nirupi-net-popup.sh nirupi-wifi.sh nirupi-bluetooth.sh; do
  src="$ROOT/vendor/noir/local/bin/$app"
  if [[ -f $src ]]; then
   dest="$HOME/.local/bin/$app"
   managed_helper_install "$app" "$src" "$dest"
  fi
   done
 # sxiv was renamed to nsxiv on Arch; keep the script's `sxiv` name working.
 if ! command -v sxiv >/dev/null 2>&1 && command -v nsxiv >/dev/null 2>&1; then
  ln -sf "$(command -v nsxiv)" "$HOME/.local/bin/sxiv"
 fi
 # Bash completion + manual page.
 if [[ -f $ROOT/vendor/noir/local/share/bash-completion/completions/nirupi ]]; then
  mkdir -p "$HOME/.local/share/bash-completion/completions"
  managed_config_install 'bash-completion/nirupi' \
    "$ROOT/vendor/noir/local/share/bash-completion/completions/nirupi" \
    "$HOME/.local/share/bash-completion/completions/nirupi"
 fi
 if [[ -f $ROOT/runtime/nirupi.1 ]]; then
  mkdir -p "$HOME/.local/share/man/man1"
  managed_config_install 'man/nirupi.1' "$ROOT/runtime/nirupi.1" "$HOME/.local/share/man/man1/nirupi.1"
 fi
 # Per-workspace wallpaper config example (created once, then yours to edit).
 if [[ ! -e $HOME/.config/nirupi/wallpapers.conf && -f $ROOT/runtime/wallpapers.conf.example ]]; then
  mkdir -p "$HOME/.config/nirupi"
  put_file "$ROOT/runtime/wallpapers.conf.example" "$HOME/.config/nirupi/wallpapers.conf" 0644
 fi
 # Autostart: the directory (entries run at login) + a documentation example.
 mkdir -p "$HOME/.config/nirupi/autostart"
 if [[ -f $ROOT/runtime/autostart.example ]]; then
  managed_config_install 'autostart/example' "$ROOT/runtime/autostart.example" "$HOME/.config/nirupi/autostart.example" 0644
 fi
 # Screensaver slideshow: point ~/Pictures/Screensaver at the Nextcloud folder
 # when it exists, so pictures sync across machines. A plain directory (no
 # Nextcloud) is left alone; no link is created when the target is missing.
 screensaver_link
 # Calendar settings example (created once; edited in the TUI).
 if [[ ! -e $HOME/.config/nirupi/calendar.conf && -f $ROOT/runtime/calendar.conf.example ]]; then
  mkdir -p "$HOME/.config/nirupi"
  put_file "$ROOT/runtime/calendar.conf.example" "$HOME/.config/nirupi/calendar.conf" 0644
 fi
 # Fleet hosts for `nirupi fleet` (created once; user-owned).
 if [[ ! -e $HOME/.config/nirupi/fleet.conf && -f $ROOT/runtime/fleet.conf.example ]]; then
  mkdir -p "$HOME/.config/nirupi"
  put_file "$ROOT/runtime/fleet.conf.example" "$HOME/.config/nirupi/fleet.conf" 0644
 fi
 # Session launcher is NIRUPI-owned: keep it fresh on --update-dots too.
 managed_helper_install nirupi-session "$ROOT/runtime-session.sh" "$HOME/.local/bin/nirupi-session"
 # Startx users: refresh ~/.xinitrc only when it already exists.
 if [[ -f $HOME/.xinitrc && ! -L $HOME/.xinitrc ]]; then
  managed_config_install 'session/xinitrc' "$ROOT/runtime-xinitrc" "$HOME/.xinitrc" 0755
 fi
}
install_desktop() (
 local app stage bin_dir="$HOME/.local/lib/nirupi/$VERSION/bin" src dest desktop
 local -a stages=()
 # Build stages are placed under a single temporary parent so they can be
 # cleaned deterministically on success and on compilation failure.
 local stage_root
 stage_root="$(mktemp -d)"
 trap 'rm -rf -- "$stage_root"' EXIT
 # Temporary build directories are removed after build/deployment or an ordinary function failure.
 mkdir -p "$bin_dir" "$HOME/.local/bin" "$HOME/.config" "$BACKUP_DIR"
 # Archive (never delete) foreign binaries/symlinks that would block a link.
 resolve_binary_conflicts "$RUN_ID"
 # Build all apps before installing any of them; avoid overwriting currently running binaries.
 for app in dwm dmenu st slock; do
  stage="$(mktemp -d "$stage_root/build.XXXXXXXX")"; stages+=("$stage")
  cp -a "$ROOT/vendor/suckless/$app/." "$stage/"
  if [[ $app == dwm ]]; then
   # Build source must match the bundled dwm.c. Only a config whose schema
   # version is at least the bundled one is safe to compile; older or unmarked
   # user configs are preserved as config.h.nirupi-new and the bundled config
   # is built instead.
   local dwm_build_custom="$HOME/.config/suckless/dwm/config.h"
   if [[ -e $dwm_build_custom || -L $dwm_build_custom ]]; then
    if [[ -L $dwm_build_custom || ! -f $dwm_build_custom ]]; then
     die "Unsafe DWM configuration path: $dwm_build_custom"
    fi
    if ! dwm_config_current "$dwm_build_custom" "$ROOT/vendor/suckless/dwm/config.h"; then
     warn "Existing DWM config.h is not current (schema v$(dwm_config_version "$dwm_build_custom") < v$(dwm_config_version "$ROOT/vendor/suckless/dwm/config.h")); building the bundled config (your file is preserved as config.h.nirupi-new)"
     dwm_build_custom=""
    fi
   else
    dwm_build_custom=""
   fi
   select_dwm_build_config "$ROOT/vendor/suckless/dwm/config.h" \
     "$dwm_build_custom" "$stage/config.h"
  fi
  log "Building $app"
  if ! make -C "$stage" -j "$(nproc)"; then
   warn "Build failed; active binaries remain untouched"
   rm -rf -- "$stage_root"
   return 1
  fi
  if [[ ! -x $stage/$app ]]; then die "Build produced no executable: $app"; fi
 done
 # Validate every build output before installing the first executable.
 for app in dmenu_run dmenu_path stest; do
  [[ -f ${stages[1]}/$app ]] || die "Missing dmenu helper: $app"
 done
 for app in dwm dmenu st slock; do
  case "$app" in
   dwm) src="${stages[0]}/dwm";; dmenu) src="${stages[1]}/dmenu";;
   st) src="${stages[2]}/st";; slock) src="${stages[3]}/slock";;
  esac
  [[ -x $src ]] || die "Missing executable build output: $app"
 done
 for app in dwm dmenu st; do
  case "$app" in dwm) src="${stages[0]}/dwm";; dmenu) src="${stages[1]}/dmenu";; st) src="${stages[2]}/st";; esac
  dest="$bin_dir/$app"
  put_file "$src" "$dest" 0755
  link_binary "$dest" "$HOME/.local/bin/$app"
 done
 for app in dmenu_run dmenu_path stest; do
  src="${stages[1]}/$app"
  [[ -f $src ]] || die "Missing dmenu helper: $app"
  dest="$bin_dir/$app"
  put_file "$src" "$dest" 0755
  link_binary "$dest" "$HOME/.local/bin/$app"
 done
  # slock needs a setuid-root copy to read the password database.
  put_file "${stages[3]}/slock" "$bin_dir/slock" 0755
  ensure_slock "$bin_dir/slock"
  install_helpers
 # Preferred browser + the personal default Git repositories in ~/Git.
 ensure_helium
 ensure_signal
 install_default_repos
 # Only initialize GTK on clean profiles; upgrades preserve LXAppearance choices.
 "$HOME/.local/bin/nirupi-appearance" default || warn "GTK appearance setup skipped; use nirupi appearance status"
 # Keep user preferences separate from the managed status script.
 local status_conf="$HOME/.config/nirupi/status.conf"
 if [[ ! -e $status_conf && ! -L $status_conf ]]; then
  mkdir -p "$HOME/.config/nirupi"
  put_file "$ROOT/runtime/status.conf.example" "$status_conf" 0644
 fi
 local session_conf="$HOME/.config/nirupi/session.conf"
 if [[ ! -e $session_conf && ! -L $session_conf ]]; then
  mkdir -p "$HOME/.config/nirupi"
  put_file "$ROOT/runtime/session.conf.example" "$session_conf" 0644
 fi
 # Update only previously recorded, unchanged NIRUPI configuration assets.
  mkdir -p "$HOME/.config/suckless/dwm"
  local dwm_cfg="$HOME/.config/suckless/dwm/config.h"
  # Three-way merge: an unmodified managed config is upgraded to the bundled
  # version that was just built; a modified/untracked config is preserved and
  # receives a sibling *.nirupi-new proposal. Binary and config never diverge.
  managed_config_install 'dwm/config.h' "$ROOT/vendor/suckless/dwm/config.h" "$dwm_cfg"
  for app in kitty fish rofi alacritty gtk-3.0 cmus tmux lazygit micro aerc dunst; do
  [[ -d $ROOT/vendor/noir/config/$app ]] || continue
  if [[ -L $HOME/.config/$app ]]; then warn "Preserving symlink ~/.config/$app"; continue; fi
  if [[ -e $HOME/.config/$app && ! -d $HOME/.config/$app ]]; then
   warn "Preserving non-directory config path ~/.config/$app"; continue
  fi
  mkdir -p "$HOME/.config/$app"
  while IFS= read -r -d '' src; do
   [[ $(basename "$src") == fish_variables ]] && continue
   dest="$HOME/.config/$app/${src#"$ROOT/vendor/noir/config/$app/"}"
   managed_config_install "config/$app/${src#"$ROOT/vendor/noir/config/$app/"}" "$src" "$dest"
  done < <(find "$ROOT/vendor/noir/config/$app" -type f -print0)
 done
  managed_config_install dotfiles/Xresources "$ROOT/vendor/noir/dotfiles/.Xresources" "$HOME/.Xresources"
   # Browser dark-mode flags, environment.d and GTK4 Noir defaults.
   theme_apply_browser_flags "$ROOT/vendor/noir"
   theme_apply_environment
   theme_apply_gtk4
   # Generate rofi/dunst/SDDM assets from the token palette.
   NIRUPI_NOIR_DIR="$ROOT/vendor/noir" theme_load_tokens
   theme_render_rofi
   theme_render_dunst
   theme_render_picom
   theme_render_sddm
   # Generated per-app colour fragments (included by the bundled app configs).
   theme_render_kitty
   theme_render_alacritty
   theme_render_fish
   theme_render_tmux
   theme_render_lazygit
   theme_render_micro
   theme_render_aerc
   theme_render_cmus
   theme_render_statusbar
   # Deploy the reusable bundle so `nirupi theme|dots|migrate` work after install.
   deploy_bundle
  local user_session="$HOME/.local/bin/nirupi-session"
 managed_config_install 'session/nirupi-session' "$ROOT/runtime-session.sh" "$user_session" 0755
 managed_config_install 'session/xinitrc' "$ROOT/runtime-xinitrc" "$HOME/.xinitrc" 0755
 check_system_session_conflicts
 check_display_manager_conflicts
 # If a global launcher exists but does not run the user session (e.g. an older
 # NIRUPI write, or a hand-written wrapper), replace it with a backup instead of
 # failing the whole install.
 if [[ -e /usr/local/bin/nirupi-session || -L /usr/local/bin/nirupi-session ]]; then
  if ! grep -Fq '.local/bin/nirupi-session' /usr/local/bin/nirupi-session 2>/dev/null; then
   if [[ -L /usr/local/bin/nirupi-session ]]; then
    die 'Existing /usr/local/bin/nirupi-session is a symlink; move it aside and retry'
   fi
   warn 'Replacing a foreign /usr/local/bin/nirupi-session (backup kept)'
   sudo cp -a /usr/local/bin/nirupi-session "/usr/local/bin/nirupi-session.bak-$(date +%Y%m%d-%H%M%S)" \
     || warn 'Could not back up the existing launcher'
   printf '#!/bin/sh\nexec "${HOME}/.local/bin/nirupi-session"\n' | sudo tee /usr/local/bin/nirupi-session >/dev/null
   sudo chmod 0755 /usr/local/bin/nirupi-session
  fi
 fi
 if [[ -e /usr/share/xsessions/nirupi-dwm.desktop || -L /usr/share/xsessions/nirupi-dwm.desktop ]]; then
  warn 'Existing NIRUPI session file detected; preserving it'
 else
  desktop="$(mktemp)"
  printf '[Desktop Entry]\nName=NIRUPI DWM\nComment=NIRU Noir X11 session\nExec=/usr/local/bin/nirupi-session\nType=Application\nDesktopNames=DWM\n' > "$desktop"
  sudo install -d -m 0755 /usr/local/bin
  if [[ -e /usr/local/bin/nirupi-session || -L /usr/local/bin/nirupi-session ]]; then
   warn 'Existing global NIRUPI session entry preserved; verify it manually'
  else
   printf '#!/bin/sh\nexec "${HOME}/.local/bin/nirupi-session"\n' | sudo tee /usr/local/bin/nirupi-session >/dev/null
   sudo chmod 0755 /usr/local/bin/nirupi-session
  fi
  sudo install -d /usr/share/xsessions
  sudo install -m 0644 "$desktop" /usr/share/xsessions/nirupi-dwm.desktop
  rm -f "$desktop"
 fi
 if [[ $SESSION == sddm ]]; then configure_sddm; fi
 log 'Desktop files installed'
)
configure_sddm(){
 local answer
 printf '\nEnable SDDM and install the NIRU theme? Type SDDM to confirm: '
 read -r answer
 [[ $answer == SDDM ]] || { warn 'SDDM theme/service setup skipped'; return 0; }
 if [[ $DISTRO != void ]]; then
  if systemctl is-enabled --quiet gdm.service 2>/dev/null || systemctl is-enabled --quiet lightdm.service 2>/dev/null || systemctl is-enabled --quiet lxdm.service 2>/dev/null; then
   warn 'Another display manager enabled; SDDM setup blocked'
   return 0
  fi
 fi
 sudo install -d /usr/share/sddm/themes/niru-noir /etc/sddm.conf.d
 if [[ -e /usr/share/sddm/themes/niru-noir/Main.qml ]]; then
  warn 'Existing NIRU theme preserved'
 else
  # Prefer the token-colored theme staged by the theme engine.
  NIRUPI_NOIR_DIR="$ROOT/vendor/noir" theme_load_tokens
  theme_render_sddm
  if [[ -f "$HOME/.local/share/nirupi/sddm/Main.qml" ]]; then
   sudo cp -a "$HOME/.local/share/nirupi/sddm/." /usr/share/sddm/themes/niru-noir/
  else
   sudo cp -a "$ROOT/vendor/sddm/." /usr/share/sddm/themes/niru-noir/
  fi
 fi
 if [[ -e /etc/sddm.conf.d/10-niru-noir.conf ]]; then
  warn 'Existing SDDM configuration preserved'
 else
  printf '[Theme]\nCurrent=niru-noir\n' | sudo tee /etc/sddm.conf.d/10-niru-noir.conf >/dev/null
 fi
 if [[ $DISTRO == void ]]; then
  # Void ships the SDDM service as /etc/sv/sddm; enabling it is a symlink.
  enable_void_service sddm /var/service \
    || warn 'Could not enable the sddm runit service; enable it manually: ln -s /etc/sv/sddm /var/service/'
 else
  sudo systemctl enable sddm.service || warn 'Failed to enable SDDM'
 fi
}
# Copy the reusable runtime bundle into ~/.local/lib/nirupi so the deployed
# `nirupi` CLI can re-apply the theme, update dotfiles or rebuild DWM without
# the original source checkout.
deploy_bundle(){
 local dest="$HOME/.local/lib/nirupi" f rel
 mkdir -p "$dest/lib" "$dest/noir" "$dest/src/suckless"
 for f in "$ROOT"/lib/*.sh; do
  put_file "$f" "$dest/lib/$(basename "$f")" 0644
 done
 put_file "$ROOT/VERSION" "$dest/VERSION" 0644
 while IFS= read -r -d '' f; do
  rel="${f#"$ROOT/vendor/noir/"}"
  mkdir -p "$dest/noir/$(dirname "$rel")"
  if [[ ! -f $dest/noir/$rel ]] || ! cmp -s -- "$f" "$dest/noir/$rel"; then
   cp -f -- "$f" "$dest/noir/$rel"
  fi
 done < <(find "$ROOT/vendor/noir" -type f -print0)
 while IFS= read -r -d '' f; do
  rel="${f#"$ROOT/vendor/suckless/"}"
  mkdir -p "$dest/src/suckless/$(dirname "$rel")"
  if [[ ! -f $dest/src/suckless/$rel ]] || ! cmp -s -- "$f" "$dest/src/suckless/$rel"; then
   cp -f -- "$f" "$dest/src/suckless/$rel"
  fi
 done < <(find "$ROOT/vendor/suckless" -type f -print0)
 # SDDM theme sources (colors are generated from tokens at theme apply time).
 if [[ -d $ROOT/vendor/sddm ]]; then
  while IFS= read -r -d '' f; do
   rel="${f#"$ROOT/vendor/sddm/"}"
   mkdir -p "$dest/sddm/$(dirname "$rel")"
   if [[ ! -f $dest/sddm/$rel ]] || ! cmp -s -- "$f" "$dest/sddm/$rel"; then
    cp -f -- "$f" "$dest/sddm/$rel"
   fi
  done < <(find "$ROOT/vendor/sddm" -type f -print0)
 fi
 log 'Runtime bundle deployed to ~/.local/lib/nirupi'
}
# Rebuild DWM from the deployed sources with the effective user config, then
# atomically re-link the binary. Both config and binary stay consistent.
migrate_dwm_rebuild(){
 local src_root="${NIRUPI_SUCKLESS_DIR:-}"
 [[ -n $src_root ]] || src_root="$HOME/.local/lib/nirupi/src/suckless"
 if [[ ! -d $src_root/dwm && -n ${ROOT:-} && -d $ROOT/vendor/suckless/dwm ]]; then
  src_root="$ROOT/vendor/suckless"
 fi
 [[ -d $src_root/dwm ]] || die "Missing DWM sources for rebuild: $src_root"
 local bin_dir="$HOME/.local/lib/nirupi/$VERSION/bin"
 local stage; stage="$(mktemp -d "${TMPDIR:-/tmp}/nirupi-dwm.XXXXXXXX")"
 cp -a -- "$src_root/dwm/." "$stage/"
 local user_cfg="$HOME/.config/suckless/dwm/config.h"
 if [[ -f $user_cfg && ! -L $user_cfg ]]; then
  if dwm_config_current "$user_cfg" "$src_root/dwm/config.h"; then
   cp -- "$user_cfg" "$stage/config.h"
  else
   warn "Ignoring out-of-date DWM config.h (schema v$(dwm_config_version "$user_cfg")); building the bundled config (merge config.h.nirupi-new first)"
  fi
 fi
 log "Rebuilding DWM ($VERSION)"
 if ! make -C "$stage" -j "$(nproc)"; then
  rm -rf -- "$stage"; die 'DWM rebuild failed; existing binary left untouched'
 fi
 [[ -x $stage/dwm ]] || { rm -rf -- "$stage"; die 'DWM rebuild produced no executable'; }
 mkdir -p "$bin_dir"
 put_file "$stage/dwm" "$bin_dir/dwm" 0755
 link_binary "$bin_dir/dwm" "$HOME/.local/bin/dwm"
 rm -rf -- "$stage"
 log 'DWM rebuilt and relinked'
}
# Rebuild every suckless binary NIRUPI links (dwm, dmenu, st + the dmenu
# helpers) into the current version directory and relink them. Upgrades done via
# --update-dots only rebuild dwm, so dmenu/st can otherwise linger on ancient
# versions; this brings them onto $VERSION and lets `nirupi gc` prune the old
# version directories.
migrate_binaries_rebuild(){
 local src_root="${NIRUPI_SUCKLESS_DIR:-}"
 [[ -n $src_root ]] || src_root="$HOME/.local/lib/nirupi/src/suckless"
 if [[ ! -d $src_root/dmenu && -n ${ROOT:-} && -d $ROOT/vendor/suckless/dmenu ]]; then
  src_root="$ROOT/vendor/suckless"
 fi
 [[ -d $src_root/dwm && -d $src_root/dmenu && -d $src_root/st ]] \
  || die "Missing suckless sources for rebuild: $src_root"
 local bin_dir="$HOME/.local/lib/nirupi/$VERSION/bin"
 mkdir -p "$bin_dir" "$HOME/.local/bin"
 local stage_root; stage_root="$(mktemp -d)"
 local app stage src
 declare -A stages=()
 for app in dwm dmenu st slock; do
  [[ -d $src_root/$app ]] || { warn "$app sources missing; skipping"; continue; }
  stage="$(mktemp -d "$stage_root/build.XXXXXXXX")"
  cp -a -- "$src_root/$app/." "$stage/"
  if [[ $app == dwm ]]; then
   local user_cfg="$HOME/.config/suckless/dwm/config.h"
   if [[ -f $user_cfg && ! -L $user_cfg ]] && dwm_config_current "$user_cfg" "$src_root/dwm/config.h"; then
    cp -- "$user_cfg" "$stage/config.h"
   fi
  fi
  log "Building $app"
  if ! make -C "$stage" -j "$(nproc)" >/dev/null 2>&1 || [[ ! -x $stage/$app ]]; then
   warn "$app build failed; existing binaries left untouched"
   rm -rf -- "$stage_root"; return 1
  fi
  stages[$app]="$stage"
 done
 for app in dwm dmenu st; do
  put_file "${stages[$app]}/$app" "$bin_dir/$app" 0755
  link_binary "$bin_dir/$app" "$HOME/.local/bin/$app"
 done
 # slock needs a setuid-root copy (/usr/local/bin/slock) to read the password db.
 if [[ -x ${stages[slock]}/slock ]]; then
  put_file "${stages[slock]}/slock" "$bin_dir/slock" 0755
  ensure_slock "$bin_dir/slock" 2>/dev/null || true
 fi
 for app in dmenu_run dmenu_path stest; do
  src="${stages[dmenu]}/$app"
  if [[ -f $src ]]; then
   put_file "$src" "$bin_dir/$app" 0755
   link_binary "$bin_dir/$app" "$HOME/.local/bin/$app"
  else
   warn "helper not found after build: $app"
  fi
 done
 rm -rf -- "$stage_root"
 log "Rebuilt dwm, dmenu, st, slock for $VERSION and relinked"
}
# Best-effort Helium browser provisioning. Helium is the preferred browser and
# has no distro package on Void/Arch. Debian uses the official apt repository,
# Arch uses an AUR helper when present, and any distro can use the official
# binary tarball (user-local, no sudo). Never fatal: the resolver falls back to
# firefox/brave/chromium/xdg-open.
HELIUM_DEB_REPO="${NIRUPI_HELIUM_DEB_REPO:-https://pkg.helium.computer/deb}"
HELIUM_KEY_URL="${NIRUPI_HELIUM_KEY_URL:-https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc}"
HELIUM_API="${NIRUPI_HELIUM_API:-https://api.github.com/repos/imputnet/helium-linux/releases/latest}"

# Build+install a prebuilt AUR helper package from its AUR snapshot (no helper
# needed). $1 = AUR package name (e.g. paru-bin). Returns 0 on success.
_aur_install_bin(){
 local name="$1" tmp
 tmp="$(mktemp -d "${TMPDIR:-/tmp}/$name.XXXXXXXX")" || return 1
 if curl -fsSL "https://aur.archlinux.org/cgit/aur.git/snapshot/$name.tar.gz" -o "$tmp/$name.tar.gz" 2>/dev/null \
    && tar -xzf "$tmp/$name.tar.gz" -C "$tmp" 2>/dev/null \
    && ( cd "$tmp/$name" && makepkg -f --noconfirm >/dev/null 2>&1 ) \
    && sudo pacman -U --noconfirm "$tmp/$name"/*.pkg.tar.zst >/dev/null 2>&1; then
  rm -rf -- "$tmp"; return 0
 fi
 rm -rf -- "$tmp"; return 1
}
# Arch/CachyOS: optionally bootstrap an AUR helper so AUR-only apps (such as the
# Helium browser package) install through the package manager instead of an
# upstream tarball. Opt-in: building from the AUR is a trust decision.
ensure_aur_helper(){
 [[ $DISTRO == arch || $DISTRO == cachyos ]] || return 0
 if command -v yay >/dev/null 2>&1 || command -v paru >/dev/null 2>&1; then return 0; fi
 command -v makepkg >/dev/null 2>&1 || { warn 'makepkg unavailable; skipping the AUR helper'; return 0; }
 printf 'No AUR helper (yay/paru) found. Install one from the AUR? Type AUR to install: '
 local ans; read -r ans
 [[ $ans == AUR ]] || { warn 'Skipping the AUR helper; AUR-only apps fall back to upstream tarballs'; return 0; }
 # Prefer paru-bin; if the prebuilt binary does not run (e.g. a libalpm soname
 # mismatch after a pacman upgrade) fall back to yay-bin.
 if _aur_install_bin paru-bin && paru --version >/dev/null 2>&1; then
  log 'AUR helper installed (paru)'; return 0
 fi
 command -v paru >/dev/null 2>&1 && sudo pacman -Rns --noconfirm paru-bin >/dev/null 2>&1
 if _aur_install_bin yay-bin && yay --version >/dev/null 2>&1; then
  log 'AUR helper installed (yay)'; return 0
 fi
 warn 'Could not install an AUR helper; AUR-only apps fall back to tarballs'
}

# Best-effort enable of the services the desktop expects on a clean install, so
# Tailscale/Bluetooth/Wi-Fi come up after a reboot. Never fatal.
# A leftover plain dwm.desktop (from before NIRUPI) can shadow the NIRUPI
# session, so the session-based features (idle, autostart, update check) would
# not run. If its launcher is not already the NIRUPI session, repoint it to the
# wrapper (backup kept). Best effort, systemd-agnostic.
ensure_nirupi_session(){
 local desk=/usr/share/xsessions/dwm.desktop target tmp
 [[ -f $desk ]] || return 0
 grep -q 'nirupi-session' "$desk" 2>/dev/null && return 0
 target="$(sed -n 's/^Exec=//p' "$desk" 2>/dev/null | awk '{print $1}' | head -n1)"
 [[ -n $target && -f $target ]] || return 0
 grep -q 'nirupi-session' "$target" 2>/dev/null && return 0
 log "Repointing legacy session launcher to the NIRUPI session: $target"
 sudo cp -a -- "$target" "$target.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || :
 tmp="$(mktemp)"
 printf '#!/bin/sh\n# Repointed by NIRUPI: run the maintained nirupi session.\nexec "$HOME/.local/bin/nirupi-session" "$@"\n' > "$tmp"
 if sudo cp -f -- "$tmp" "$target" && sudo chmod 0755 "$target"; then
  log 'Legacy session now runs the NIRUPI session'
 else
  warn "Could not repoint $target"
 fi
 rm -f -- "$tmp"
}

# Enable a runit service on Void by symlinking /etc/sv/<svc> into the runsvdir
# (default /var/service). Idempotent: an already-enabled service is left
# untouched. Returns non-zero when the unit is missing or the link failed.
enable_void_service(){
 local svc="${1:-}" root="${2:-/var/service}"
 [[ -n $svc ]] || return 1
 [[ -e /etc/sv/$svc ]] || return 1
 if [[ -e $root/$svc ]]; then return 0; fi
 sudo ln -s "/etc/sv/$svc" "$root/" 2>/dev/null || return 1
 log "Enabled $svc (runit)"
 return 0
}
enable_services(){
 local unit svc
 case "$DISTRO" in
  arch|cachyos|debian)
   command -v systemctl >/dev/null 2>&1 || return 0
   for unit in tailscaled bluetooth; do
    systemctl list-unit-files "$unit.service" >/dev/null 2>&1 || continue
    if sudo systemctl enable --now "$unit.service" >/dev/null 2>&1; then log "Enabled $unit.service"
    else warn "Could not enable $unit.service"; fi
   done
   if command -v nmcli >/dev/null 2>&1 \
      && ! systemctl is-active --quiet systemd-networkd 2>/dev/null \
      && ! systemctl is-active --quiet iwd 2>/dev/null; then
    systemctl list-unit-files NetworkManager.service >/dev/null 2>&1 \
      && sudo systemctl enable --now NetworkManager.service >/dev/null 2>&1 \
      && log 'Enabled NetworkManager.service'
   fi
   # Small maintenance timers: SSD trim + pacman cache cleanup.
   for unit in fstrim.timer paccache.timer; do
    systemctl list-unit-files "$unit" >/dev/null 2>&1 || continue
    sudo systemctl enable --now "$unit" >/dev/null 2>&1 && log "Enabled $unit"
   done;;
  void)
   # Void has no systemd: a runit service is enabled by symlinking its unit
   # into /var/service. dbus, elogind and polkitd come first — on a clean
   # install NetworkManager, bluetoothd and the desktop session depend on them.
   for svc in dbus elogind polkitd tailscaled bluetoothd NetworkManager; do
    [[ -e /etc/sv/$svc ]] || continue
    [[ -e /var/service/$svc ]] && continue
    enable_void_service "$svc" /var/service || warn "Could not enable $svc"
   done;;
 esac
}

# Best-effort Signal Desktop provisioning. Arch ships signal-desktop (in PKGS);
# Debian needs Signal's own apt repository. Void has no package (skipped).
ensure_signal(){
  command -v signal-desktop >/dev/null 2>&1 && return 0
  case "$DISTRO" in
    arch|cachyos) return 0;;
    debian)
      command -v curl >/dev/null 2>&1 && command -v gpg >/dev/null 2>&1 || { warn 'Signal: need curl+gpg'; return 0; }
      log 'Installing Signal Desktop from the official apt repository'
      if curl -fsSL 'https://updates.signal.org/desktop/apt/keys.asc' | sudo gpg --dearmor -o /usr/share/keyrings/signal-desktop-keyring.gpg 2>/dev/null \
         && printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main\n' | sudo tee /etc/apt/sources.list.d/signal-xenial.list >/dev/null \
         && sudo apt-get update >/dev/null 2>&1 \
         && sudo apt-get install -y signal-desktop; then
        log 'Signal Desktop installed'
      else
        warn 'Signal Desktop install failed (offline?)'
      fi;;
    *) return 0;;
  esac
}

ensure_helium_tarball(){
  command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1 || { warn 'curl/tar missing; cannot fetch Helium'; return 0; }
  local json url tmp appdir bin
  json="$(curl -fsSL "$HELIUM_API" 2>/dev/null)" || { warn 'Could not query Helium releases'; return 0; }
  url="$(printf '%s' "$json" | grep -oE 'https://[^"]*x86_64_linux\.tar\.xz' | head -n1)"
  [[ -n $url ]] || { warn 'No Helium tarball URL found'; return 0; }
  tmp="$(mktemp -d)"
  log "Downloading Helium tarball ($(basename "$url"))"
  if ! curl -fL "$url" -o "$tmp/helium.tar.xz"; then warn 'Helium download failed'; rm -rf -- "$tmp"; return 0; fi
  if ! tar -xJf "$tmp/helium.tar.xz" -C "$tmp" 2>/dev/null && ! tar -xf "$tmp/helium.tar.xz" -C "$tmp" 2>/dev/null; then
    warn 'Helium extraction failed'; rm -rf -- "$tmp"; return 0
  fi
  bin="$(find "$tmp" -maxdepth 4 -type f -name helium -print -quit 2>/dev/null)"
  [[ -n $bin && -x $bin ]] || { warn 'Helium binary not found in archive'; rm -rf -- "$tmp"; return 0; }
  appdir="$(dirname "$bin")"
  rm -rf -- "$HOME/.local/opt/helium"; mkdir -p "$HOME/.local/opt"
  mv "$appdir" "$HOME/.local/opt/helium"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.local/opt/helium/helium" "$HOME/.local/bin/helium"
  ln -sf "$HOME/.local/opt/helium/helium" "$HOME/.local/bin/helium-browser"
  rm -rf -- "$tmp"
  log 'Helium installed to ~/.local/opt/helium'
}

ensure_helium(){
  if command -v helium >/dev/null 2>&1 || command -v helium-browser >/dev/null 2>&1 \
     || [[ -x "$HOME/.local/bin/helium" || -x "$HOME/.local/bin/helium-browser" \
           || -x "$HOME/.local/opt/helium/helium" ]]; then
    log 'Helium browser already installed'; return 0
  fi
  case "$DISTRO" in
   debian)
    if command -v curl >/dev/null 2>&1 && command -v gpg >/dev/null 2>&1; then
      log 'Installing Helium from the official apt repository'
      if curl -fsSL "$HELIUM_KEY_URL" | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg 2>/dev/null \
         && printf 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/helium.gpg] %s stable main\n' "$HELIUM_DEB_REPO" | sudo tee /etc/apt/sources.list.d/helium.list >/dev/null \
         && sudo apt-get update >/dev/null 2>&1 \
         && sudo apt-get install -y helium-bin; then
        log 'Helium installed'; return 0
      fi
      warn 'Helium apt install failed; trying the binary tarball'
    fi;;
   arch|cachyos)
    if command -v yay >/dev/null 2>&1; then
      yay -S --needed --noconfirm helium-browser-bin && { log 'Helium installed (AUR)'; return 0; }
    elif command -v paru >/dev/null 2>&1; then
      paru -S --needed --noconfirm helium-browser-bin && { log 'Helium installed (AUR)'; return 0; }
    fi
    warn 'No AUR helper (yay/paru); using the Helium binary tarball';;
  esac
  ensure_helium_tarball
}

# Install a working, setuid-root slock at /usr/local/bin/slock. Our slock build
# tolerates the "nobody" group being absent (Void uses "nogroup"). We replace an
# existing regular file (backup kept) so upgrades actually take effect.
# Point ~/Pictures/Screensaver at ~/Nextcloud/Screensaver when the Nextcloud
# folder exists, so the lock-screen slideshow shows synced pictures. Absent
# Nextcloud/folder -> no link and the screensaver keeps its plain look. Never
# fatal, never replaces a real directory or a foreign symlink.
screensaver_link(){
 local target="$HOME/Nextcloud/Screensaver"
 local link="$HOME/Pictures/Screensaver"
 [[ -d $target ]] || return 0
 mkdir -p "$HOME/Pictures"
 if [[ -L $link ]]; then
  [[ "$(readlink -f "$link" 2>/dev/null)" == "$(readlink -f "$target")" ]] && return 0
  warn "Screensaver link points elsewhere; leaving $link untouched"; return 0
 fi
 if [[ -e $link ]]; then
  if [[ -d $link && -z "$(ls -A "$link" 2>/dev/null)" ]]; then
   rmdir "$link" 2>/dev/null || { warn "Could not empty-replace $link"; return 0; }
  else
   log "Using the existing $link for screensaver pictures"; return 0
  fi
 fi
 if ln -s "$target" "$link" 2>/dev/null; then
  log "Screensaver pictures linked: $link -> $target"
 else
  warn "Could not create the screensaver link $link"
 fi
}

ensure_slock(){
  local built="${1:-}"
  [[ -n $built && -x $built ]] || built="$HOME/.local/lib/nirupi/$VERSION/bin/slock"
  [[ -x $built ]] || built="$ROOT/vendor/suckless/slock/slock"
  local dest=/usr/local/bin/slock
  [[ -x $built ]] || { warn 'No slock binary to install; the lock keybinding will not work'; return 0; }
  if [[ -e $dest && ! -f $dest ]]; then
    warn "Refusing to replace non-regular $dest"; return 0
  fi
  if [[ -f $dest ]] && cmp -s -- "$built" "$dest" && [[ $(stat -c %a -- "$dest" 2>/dev/null) == 4755 ]]; then
    log 'setuid slock already installed'; return 0
  fi
  if [[ -f $dest ]]; then
    local bak="$dest.nirupi-$(date +%Y%m%d-%H%M%S).bak"
    sudo cp -a -- "$dest" "$bak" 2>/dev/null || warn "Could not back up $dest"
  fi
  if sudo install -o root -g root -m 4755 "$built" "$dest"; then
    log 'Installed setuid slock to /usr/local/bin/slock'
  else
    warn 'Could not install setuid slock; the lock keybinding may not work'
  fi
}

# Best-effort Nerd Font provisioning; never fatal. Package availability differs
# wildly per distro, so install the official release into ~/.local/share/fonts.
NERD_FONT_URL="${NIRUPI_NERD_FONT_URL:-https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip}"
ensure_nerd_font(){
 local fam dir tmp ans
 if command -v fc-match >/dev/null 2>&1; then
  fam="$(fc-match -f '%{family}' 'JetBrainsMono Nerd Font' 2>/dev/null || :)"
  case "$fam" in
   *'JetBrainsMono Nerd Font'*|*'JetBrainsMono NF'*|*'Nerd'*) log "Nerd Font available: $fam"; return 0;;
  esac
 fi
 warn 'JetBrainsMono Nerd Font not found; status bar icons may be missing'
 if [[ ${NIRUPI_INSTALL_FONT:-} != 1 ]]; then
  printf 'Download JetBrainsMono Nerd Font to ~/.local/share/fonts? Type FONT to download: '
  read -r ans; [[ $ans == FONT ]] || { warn 'Skipping Nerd Font download'; return 0; }
 fi
 command -v curl >/dev/null 2>&1 || { warn 'curl missing; cannot download font'; return 0; }
 command -v unzip >/dev/null 2>&1 || { warn 'unzip missing; install it and re-run nirupi theme apply'; return 0; }
 dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"; mkdir -p "$dir"
 tmp="$(mktemp -d)"
 if curl -fsSL "$NERD_FONT_URL" -o "$tmp/font.zip" && unzip -oq "$tmp/font.zip" -d "$dir"; then
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$dir" >/dev/null 2>&1 || :
  log "Nerd Font installed to $dir"
 else
  warn 'Nerd Font download or extraction failed; continuing without it'
 fi
 rm -rf -- "$tmp"
}
# Install opencode (AI coding agent) so `nirupi agent` works. Best effort:
# npm first, then the official installer. Never fatal.
install_opencode(){
 if command -v opencode >/dev/null 2>&1; then
  log "opencode already installed: $(command -v opencode)"; return 0
 fi
 if command -v npm >/dev/null 2>&1; then
  if npm install -g opencode-ai >/dev/null 2>&1 || sudo npm install -g opencode-ai >/dev/null 2>&1; then
   log 'opencode installed via npm (opencode-ai)'; return 0
  fi
 fi
 if command -v curl >/dev/null 2>&1; then
  if curl -fsSL https://opencode.ai/install | bash; then
   log 'opencode installed via the official installer'
   opencode_link
   return 0
  fi
 fi
 command -v opencode >/dev/null 2>&1 && opencode_link
 warn 'opencode could not be installed automatically; install it manually (https://opencode.ai)'
}
# Make opencode reachable from the session and from fish.
opencode_link(){
 [[ -x "$HOME/.opencode/bin/opencode" ]] || return 0
 mkdir -p "$HOME/.local/bin" "$HOME/.config/fish/conf.d"
 ln -sf "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"
 [[ -f "$HOME/.config/fish/conf.d/nirupi-opencode.fish" ]] || \
   printf 'fish_add_path $HOME/.opencode/bin\n' > "$HOME/.config/fish/conf.d/nirupi-opencode.fish"
 log "opencode linked into ~/.local/bin"
}
