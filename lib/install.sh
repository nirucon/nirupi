#!/usr/bin/env bash
check_system_session_conflicts(){
 local launcher="${NIRUPI_SYSTEM_LAUNCHER:-/usr/local/bin/nirupi-session}"
 local desktop="${NIRUPI_SYSTEM_DESKTOP:-/usr/share/xsessions/nirupi-dwm.desktop}"
 if [[ -e $launcher || -L $launcher ]]; then
   [[ -f $launcher && ! -L $launcher ]] ||
     die "Existing system session launcher is not a regular file: $launcher"
   grep -Fxq 'exec "${HOME}/.local/bin/nirupi-session"' "$launcher" ||
     die "Existing $launcher is unmanaged; refusing installation"
 fi
 if [[ -e $desktop || -L $desktop ]]; then
   [[ -f $desktop && ! -L $desktop ]] ||
     die "Existing desktop session entry is not a regular file: $desktop"
   grep -Fxq 'Exec=/usr/local/bin/nirupi-session' "$desktop" ||
     die "Existing $desktop is unmanaged; refusing installation"
 fi
}
# Fail before package transactions if enabling SDDM would conflict with another DM.
check_display_manager_conflicts() {
 [[ ${SESSION:-startx} == sddm ]] || return 0
 [[ $DISTRO == void ]] && return 0
 command -v systemctl >/dev/null 2>&1 || return 0
 local dm
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
 for app in dwm dmenu st dmenu_run dmenu_path stest; do
  path="$HOME/.local/bin/$app"
  if [[ -L $path ]]; then
   target="$(readlink -- "$path")"
   [[ $target == "$HOME/.local/lib/nirupi/"* ]] || die "Unmanaged symlink blocks installation: $path -> $target"
  elif [[ -e $path ]]; then
   die "Existing executable blocks NIRUPI symlink: $path"
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
install_desktop() (
 local app stage bin_dir="$HOME/.local/lib/nirupi/$VERSION/$RUN_ID/bin" src dest desktop
 local -a stages=()
 # Build stages are placed under a single temporary parent so they can be
 # cleaned deterministically on success and on compilation failure.
 local stage_root
 stage_root="$(mktemp -d)"
 trap 'rm -rf -- "$stage_root"' EXIT
 # Temporary build directories are removed after build/deployment or an ordinary function failure.
 mkdir -p "$bin_dir" "$HOME/.local/bin" "$HOME/.config" "$BACKUP_DIR"
 # Refuse unexpected collisions before any binary is linked.
 for app in dwm dmenu st dmenu_run dmenu_path stest; do
  if [[ -e "$HOME/.local/bin/$app" && ! -L "$HOME/.local/bin/$app" ]]; then
   die "Existing executable blocks NIRUPI symlink: ~/.local/bin/$app (not overwritten)"
  fi
 done
 # Detect unmanaged symlinks before making changes to any user binary.
 for app in dwm dmenu st dmenu_run dmenu_path stest; do
  local current="$HOME/.local/bin/$app" target
  if [[ -L $current ]]; then
   target="$(readlink -- "$current")"
   [[ $target == "$HOME/.local/lib/nirupi/"* ]] || die "Unmanaged symlink blocks installation: $current -> $target"
  fi
 done
 # Build all apps before installing any of them; avoid overwriting currently running binaries.
 for app in dwm dmenu st slock; do
  stage="$(mktemp -d "$stage_root/build.XXXXXXXX")"; stages+=("$stage")
  cp -a "$ROOT/vendor/suckless/$app/." "$stage/"
  if [[ $app == dwm ]]; then
   select_dwm_build_config "$ROOT/vendor/suckless/dwm/config.h" \
     "$HOME/.config/suckless/dwm/config.h" "$stage/config.h"
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
 # slock needs privileged installation, and is never silently made setuid-root.
 put_file "${stages[3]}/slock" "$bin_dir/slock" 0755
 printf '\nEnable Slock (requires setuid-root binary at /usr/local/bin/slock)? Type SLOCK to approve: '
 local lock_answer; read -r lock_answer
 if [[ $lock_answer == SLOCK ]]; then
  if [[ -e /usr/local/bin/slock || -L /usr/local/bin/slock ]]; then
   warn 'Existing /usr/local/bin/slock not replaced; inspect it manually'
  else
   sudo install -o root -g root -m 4755 "$bin_dir/slock" /usr/local/bin/slock
   log 'Slock installed with setuid-root; review before production use'
  fi
 else
  warn 'Slock not activated; lock keybinding will not be functional without a secure system slock'
 fi
 if [[ -e $HOME/.local/bin/nirupi-updates || -L $HOME/.local/bin/nirupi-updates ]]; then
  warn 'Preserving existing nirupi-updates helper'
 else
  put_file "$ROOT/runtime/nirupi-updates" "$HOME/.local/bin/nirupi-updates" 0755
 fi
 for app in dwm-status.sh wallrotate.sh wallpaperchange.sh sleep-suspend.sh dwm-keybindings.sh apply-screenlayout.sh clip-menu.sh clip-save.sh screenshot-browser.sh screenshot-select.sh sr-dmenu.sh tui-dmenu.sh webapp-ai-launcher.sh webapp-dmenu-brave.sh webapp-dmenu.sh; do
  src="$ROOT/vendor/noir/local/bin/$app"
  if [[ -f $src ]]; then
   dest="$HOME/.local/bin/$app"
   managed_helper_install "$app" "$src" "$dest"
  fi
 done
 # Update only previously recorded, unchanged NIRUPI configuration assets.
 local rofi_theme_src="$ROOT/vendor/noir/local/share/rofi/themes/Black-Metal.rasi"
 local rofi_theme_dest="$HOME/.local/share/rofi/themes/Black-Metal.rasi"
 managed_config_install 'rofi/Black-Metal.rasi' "$rofi_theme_src" "$rofi_theme_dest"
 mkdir -p "$HOME/.config/suckless/dwm"
 local dwm_cfg="$HOME/.config/suckless/dwm/config.h"
  # Never silently change the DWM config after building a binary from it.
  # A future explicit migration command can update and rebuild atomically.
  if [[ -e $dwm_cfg || -L $dwm_cfg ]]; then
   warn 'Existing DWM config preserved to match the just-built binary'
  else
   managed_config_install 'dwm/config.h' "$ROOT/vendor/suckless/dwm/config.h" "$dwm_cfg"
  fi
 for app in kitty fish dunst picom rofi alacritty gtk-3.0 cmus; do
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
 local user_session="$HOME/.local/bin/nirupi-session"
 managed_config_install 'session/nirupi-session' "$ROOT/runtime-session.sh" "$user_session" 0755
 managed_config_install 'session/xinitrc' "$ROOT/runtime-xinitrc" "$HOME/.xinitrc" 0755
 check_system_session_conflicts
 check_display_manager_conflicts
 # Do not create an Xsession entry that points to a foreign global launcher.
 if [[ -e /usr/local/bin/nirupi-session || -L /usr/local/bin/nirupi-session ]]; then
  if ! grep -Fq '${HOME}/.local/bin/nirupi-session' /usr/local/bin/nirupi-session 2>/dev/null; then
   die 'Existing /usr/local/bin/nirupi-session is unmanaged; refusing session registration'
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
 else
  # Void's runit service cannot be safely enabled until its service path is verified.
  warn 'Void: SDDM service activation requires manual verification; theme files will be installed'
 fi
 sudo install -d /usr/share/sddm/themes/niru-noir /etc/sddm.conf.d
 if [[ -e /usr/share/sddm/themes/niru-noir/Main.qml ]]; then
  warn 'Existing NIRU theme preserved'
 else
  sudo cp -a "$ROOT/vendor/sddm/." /usr/share/sddm/themes/niru-noir/
 fi
 if [[ -e /etc/sddm.conf.d/10-niru-noir.conf ]]; then
  warn 'Existing SDDM configuration preserved'
 else
  printf '[Theme]\nCurrent=niru-noir\n' | sudo tee /etc/sddm.conf.d/10-niru-noir.conf >/dev/null
 fi
 if [[ $DISTRO != void ]]; then
  sudo systemctl enable sddm.service || warn 'Failed to enable SDDM'
fi
}
