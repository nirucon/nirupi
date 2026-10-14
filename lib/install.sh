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
 # Back-compat: dwm builds on some earlier versions invoked this without .sh
 ln -sf nirupi-status-click.sh "$HOME/.local/bin/nirupi-status-click"
 for app in dwm-status.sh wallrotate.sh wallpaperchange.sh sleep-suspend.sh dwm-keybindings.sh apply-screenlayout.sh clip-menu.sh clip-save.sh screenshot-browser.sh screenshot-select.sh sr-dmenu.sh tui-dmenu.sh webapp-ai-launcher.sh webapp-dmenu-brave.sh webapp-dmenu.sh nirupi-keys.sh nirupi-menu.sh nirupi-agent.sh nirupi-backup.sh nirupi-status-click.sh; do
  src="$ROOT/vendor/noir/local/bin/$app"
  if [[ -f $src ]]; then
   dest="$HOME/.local/bin/$app"
   managed_helper_install "$app" "$src" "$dest"
  fi
 done
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
   # Build source must match the bundled dwm.c. Only a config that carries the
   # current NIRUPI_CONFIG_VERSION marker is safe to compile; older user configs
   # are preserved as config.h.nirupi-new and the bundled config is built instead.
   local dwm_build_custom="$HOME/.config/suckless/dwm/config.h"
   if [[ -e $dwm_build_custom || -L $dwm_build_custom ]]; then
    if [[ -L $dwm_build_custom || ! -f $dwm_build_custom ]]; then
     die "Unsafe DWM configuration path: $dwm_build_custom"
    fi
    if ! grep -q 'NIRUPI_CONFIG_VERSION' "$dwm_build_custom"; then
     warn "Existing DWM config.h predates the new patches; building the bundled config (your file is preserved as config.h.nirupi-new)"
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
 install_helpers
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
 local rofi_theme_src="$ROOT/vendor/noir/local/share/rofi/themes/Black-Metal.rasi"
 local rofi_theme_dest="$HOME/.local/share/rofi/themes/Black-Metal.rasi"
 managed_config_install 'rofi/Black-Metal.rasi' "$rofi_theme_src" "$rofi_theme_dest"
  mkdir -p "$HOME/.config/suckless/dwm"
  local dwm_cfg="$HOME/.config/suckless/dwm/config.h"
  # Three-way merge: an unmodified managed config is upgraded to the bundled
  # version that was just built; a modified/untracked config is preserved and
  # receives a sibling *.nirupi-new proposal. Binary and config never diverge.
  managed_config_install 'dwm/config.h' "$ROOT/vendor/suckless/dwm/config.h" "$dwm_cfg"
  for app in kitty fish dunst picom rofi alacritty gtk-3.0 cmus tmux lazygit micro aerc; do
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
  # Deploy the reusable bundle so `nirupi theme|dots|migrate` work after install.
  deploy_bundle
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
  if grep -q 'NIRUPI_CONFIG_VERSION' "$user_cfg"; then
   cp -- "$user_cfg" "$stage/config.h"
  else
   warn "Ignoring out-of-date DWM config.h; building the bundled config (merge config.h.nirupi-new first)"
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
