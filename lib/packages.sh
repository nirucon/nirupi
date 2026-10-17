#!/usr/bin/env bash
# Package selection and installation.
#
# Profiles:
#   minimal  - only what the desktop, status bar, audio, network and tools need
#   desktop   - the default NIRUPI desktop (default)
#   full      - desktop plus the optional application set
#
# The base list is always installed with the native package manager. Optional
# application packages are installed only when the user opts in (or --profile
# full). Hardware firmware/VA-API packages are best-effort for every profile.
valid_profile(){
 case "${1:-}" in
  minimal|desktop|full) return 0;;
  *) return 1;;
 esac
}

packages(){
 local profile="${NIRUPI_PROFILE:-desktop}"
 if ! valid_profile "$profile"; then
  warn "Unknown NIRUPI profile '$profile'; using desktop"
  profile=desktop
 fi
 NIRUPI_PROFILE="$profile"
 PKGS=()
 OPTIONAL_PKGS=()
 HW_PKGS=()
 MINIMAL_EXCLUDE=()
 case "$DISTRO" in
 arch|cachyos)
  PKGS=(base-devel git xorg-server xorg-xinit xorg-xsetroot xorg-xrandr xorg-xrdb xorg-setxkbmap xorg-xprop
   libx11 libxcb libxft libxinerama imlib2 fontconfig freetype2 pkgconf
   fish kitty feh dunst rofi alacritty pcmanfm arandr
   playerctl brightnessctl maim xclip libnotify flameshot
   pipewire wireplumber pipewire-pulse dbus glib2
   picom xss-lock gammastep imagemagick unzip zip xdotool xdg-utils xorg-xinput ffmpeg gnupg
   xf86-input-libinput mesa sof-firmware alsa-ucm-conf pipewire-alsa
   man-db bash-completion xdg-desktop-portal xdg-desktop-portal-gtk noto-fonts
   networkmanager bluez-utils papirus-icon-theme noto-fonts-emoji nsxiv
   python python-pip mpv yt-dlp pacman-contrib curl jq gawk fzf util-linux)
  OPTIONAL_PKGS=(xautolock xidlehook redshift acl signal-desktop
   btop bat eza fd ripgrep zoxide fastfetch cava librespot
   gimp filezilla vlc cmus scrot p7zip unrar neovim micro meld
   gvfs udisks2 udiskie blueman lxappearance qt5ct qt6ct kvantum
   nextcloud-client flatpak pyside6 hunspell tesseract satty)
  MINIMAL_EXCLUDE=(alacritty pcmanfm arandr flameshot mpv yt-dlp);;
 debian)
  PKGS=(build-essential git xorg xinit x11-xserver-utils x11-xkb-utils x11-utils
   libx11-dev libxcb1-dev libx11-xcb-dev libxcb-res0-dev libxft-dev libxinerama-dev
   libimlib2-dev libfontconfig1-dev libfreetype-dev pkg-config
   fish kitty feh dunst rofi alacritty pcmanfm arandr
   playerctl brightnessctl maim xclip libnotify-bin flameshot
   pipewire wireplumber pipewire-pulse dbus dbus-x11 libglib2.0-bin
   picom xss-lock gammastep imagemagick unzip zip xdotool xdg-utils xinput ffmpeg gnupg
   xserver-xorg-input-libinput libgl1-mesa-dri alsa-ucm-conf pipewire-alsa
   man-db bash-completion xdg-desktop-portal xdg-desktop-portal-gtk fonts-noto-core
   network-manager bluez papirus-icon-theme fonts-noto-color-emoji sxiv
   python3 python3-pip python3-venv mpv yt-dlp curl jq gawk fzf util-linux)
  OPTIONAL_PKGS=(xautolock xidlehook redshift hunspell-sv
   btop bat eza fd-find ripgrep zoxide fastfetch cava librespot
   gimp filezilla vlc cmus scrot unrar-free p7zip-full neovim micro meld
   gvfs udisks2 udiskie blueman lxappearance qt5ct qt6ct kvantum
   nextcloud-desktop flatpak python3-pyside6.qtcore python3-pyside6.qtgui python3-pyside6.qtwidgets hunspell tesseract-ocr satty)
  MINIMAL_EXCLUDE=(alacritty pcmanfm arandr flameshot mpv yt-dlp);;
 void)
  PKGS=(base-devel git xorg xinit xsetroot xrandr xrdb setxkbmap xprop
   libX11-devel libxcb-devel libXft-devel libXinerama-devel
   imlib2-devel fontconfig-devel freetype-devel pkg-config
   fish-shell kitty feh dunst rofi alacritty pcmanfm arandr
   playerctl brightnessctl maim xclip libnotify flameshot
   pipewire wireplumber dbus glib
   picom xss-lock gammastep ImageMagick unzip zip xdotool xdg-utils xinput ffmpeg gnupg
   xf86-input-libinput mesa mesa-dri alsa-ucm-conf alsa-pipewire man-db
   bash-completion xdg-desktop-portal xdg-desktop-portal-gtk noto-fonts-ttf sof-firmware
   void-repo-nonfree
   NetworkManager bluez papirus-icon-theme noto-fonts-emoji sxiv
   python3 python3-pip mpv yt-dlp curl jq gawk fzf util-linux)
  OPTIONAL_PKGS=(xautolock xidlehook redshift hunspell-sv
   btop bat eza fd ripgrep zoxide fastfetch cava librespot
   gimp filezilla vlc cmus scrot unrar p7zip neovim micro meld
   gvfs udisks2 udiskie blueman lxappearance qt5ct qt6ct kvantum
   nextcloud-client flatpak python3-pyside6 hunspell tesseract-ocr satty)
  MINIMAL_EXCLUDE=(alacritty pcmanfm arandr flameshot mpv yt-dlp);;
 esac
 if [[ $profile == minimal ]]; then
  local -a kept=()
  local p ex keep
  for p in "${PKGS[@]}"; do
   keep=1
   for ex in "${MINIMAL_EXCLUDE[@]}"; do
    [[ $p == "$ex" ]] && { keep=0; break; }
   done
   (( keep )) && kept+=("$p")
  done
  PKGS=("${kept[@]}")
 fi
 # SDDM is only needed when the user selected that session target.
 if [[ ${SESSION:-startx} == sddm ]]; then
  case "$DISTRO" in
   arch|cachyos) PKGS+=(sddm qt6-declarative);;
   debian) PKGS+=(sddm qml6-module-qtquick qml6-module-qtquick-controls);;
   void) PKGS+=(sddm qt6-declarative);;
  esac
 fi
 detect_hardware_packages
}
# Detect CPU/GPU vendor and queue the matching microcode + VA-API/Vulkan bits.
# Mesa (OpenGL) is already in PKGS for every distro. These packages are
# installed best-effort; a missing package never aborts a clean install.
detect_hardware_packages(){
 local cpu="" gpu="" f v
 grep -qm1 'GenuineIntel' /proc/cpuinfo 2>/dev/null && cpu=intel
 grep -qm1 'AuthenticAMD' /proc/cpuinfo 2>/dev/null && cpu=amd
 for f in /sys/class/drm/card*/device/vendor; do
  [[ -r $f ]] || continue
  v="$(cat "$f" 2>/dev/null)"
  case "$v" in
   0x8086) gpu=intel;;
   0x1002|0x1022) gpu=amd;;
   0x10de) gpu=nvidia;;
  esac
  [[ -n $gpu ]] && break
 done
 declare -F log >/dev/null 2>&1 && log "Detected CPU=$cpu GPU=${gpu:-unknown}"
 HW_PKGS=()
 case "$DISTRO" in
  arch|cachyos)
   [[ $cpu == intel ]] && HW_PKGS+=(intel-ucode)
   [[ $cpu == amd ]] && HW_PKGS+=(amd-ucode)
   case "$gpu" in
    intel) HW_PKGS+=(vulkan-intel intel-media-driver);;
    amd)   HW_PKGS+=(vulkan-radeon libva-mesa-driver);;
   esac;;
  debian)
   [[ $cpu == intel ]] && HW_PKGS+=(intel-microcode)
   [[ $cpu == amd ]] && HW_PKGS+=(amd64-microcode)
   case "$gpu" in
    intel) HW_PKGS+=(mesa-vulkan-drivers intel-media-va-driver);;
    amd)   HW_PKGS+=(mesa-vulkan-drivers mesa-va-drivers);;
   esac;;
  void)
   [[ $cpu == intel ]] && HW_PKGS+=(intel-ucode)
   [[ $cpu == amd ]] && HW_PKGS+=(amd-ucode)
   case "$gpu" in
    intel) HW_PKGS+=(mesa-vulkan-intel intel-media-driver);;
    amd)   HW_PKGS+=(mesa-vulkan-radeon mesa-vaapi);;
   esac;;
 esac
 [[ $gpu == nvidia ]] && { declare -F warn >/dev/null 2>&1 && warn 'NVIDIA GPU detected: install the driver yourself (nvidia/nvidia-open) and rebuild the initramfs; see the Arch/Debian/Void wiki'; }
 return 0
}
# Void package names are not always identical to their executable names.
# Resolve all requested packages before starting an XBPS transaction.
void_packages_preflight(){
 [[ $DISTRO == void ]] || return 0
 require xbps-query
 local pkg missing=0
 for pkg in "${PKGS[@]}"; do
  if ! xbps-query -R "$pkg" >/dev/null 2>&1 && ! xbps-query -p pkgver "$pkg" >/dev/null 2>&1; then
   warn "Void package unavailable: $pkg"
   missing=1
  fi
 done
 (( missing == 0 )) || die 'Void package preflight failed; check repositories and package names before applying'
 log "Void XBPS package preflight passed (${#PKGS[@]} packages)"
}
install_packages(){
 log "Preparing ${#PKGS[@]} packages (profile: ${NIRUPI_PROFILE:-desktop})"
 case "$DISTRO" in
  arch|cachyos) # Arch requires coherent package databases. Never perform a silent partial upgrade.
  warn 'Arch/CachyOS: packages must be installed with a full synchronized upgrade to avoid partial upgrades.'
  printf 'Type UPGRADE to approve a full pacman system upgrade plus package installation: '
  read -r pacman_answer
  [[ $pacman_answer == UPGRADE ]] || die 'Pacman installation cancelled'
  sudo pacman -Sy --needed --noconfirm archlinux-keyring || warn 'keyring refresh failed (continuing)'
  sudo pacman -Syu --needed -- "${PKGS[@]}";;
  debian) sudo apt-get update && sudo apt-get install -y --no-install-recommends -- "${PKGS[@]}";;
  void)
   void_packages_preflight
   # Void also expects a synchronized system. Keep the default conservative
   # (install only), but offer the full upgrade explicitly.
   if [[ ${NIRUPI_FULL_UPGRADE:-ask} == 1 ]]; then
    sudo xbps-install -Syu -- "${PKGS[@]}"
   elif [[ ${NIRUPI_FULL_UPGRADE:-ask} == ask && -t 0 ]]; then
    printf 'Type UPGRADE for a full synchronized xbps system upgrade (Enter installs only): '
    read -r xbps_answer
    if [[ $xbps_answer == UPGRADE ]]; then
     sudo xbps-install -Syu -- "${PKGS[@]}"
    else
     sudo xbps-install -S -- "${PKGS[@]}"
    fi
   else
    sudo xbps-install -S -- "${PKGS[@]}"
   fi;;
 esac
}
# Optional application packages are best-effort. Hardware packages (microcode,
# VA-API/Vulkan) are always attempted because they affect correctness and
# performance on the detected machine. A missing name in one repo must never
# abort a clean install.
install_optional_packages(){
 local -a todo=("${HW_PKGS[@]}")
 local p
 if [[ ${NIRUPI_INSTALL_OPTIONAL:-0} == 1 || ${NIRUPI_PROFILE:-desktop} == full ]]; then
  todo+=("${OPTIONAL_PKGS[@]}")
 fi
 ((${#todo[@]})) || return 0
 log "Installing ${#todo[@]} optional/hardware package(s) (best effort)"
 case "$DISTRO" in
  arch|cachyos)
   for p in "${todo[@]}"; do
    if sudo pacman -Si -- "$p" >/dev/null 2>&1; then
     sudo pacman -S --needed --noconfirm -- "$p" || warn "optional install failed: $p"
    else warn "optional package unavailable: $p"; fi
   done;;
  debian)
   for p in "${todo[@]}"; do
    if apt-cache show -- "$p" >/dev/null 2>&1; then
     sudo apt-get install -y --no-install-recommends -- "$p" || warn "optional install failed: $p"
    else warn "optional package unavailable: $p"; fi
   done;;
  void)
   for p in "${todo[@]}"; do
    if xbps-query -R "$p" >/dev/null 2>&1 || xbps-query -p pkgver "$p" >/dev/null 2>&1; then
     sudo xbps-install -Sy -- "$p" || warn "optional install failed: $p"
    else warn "optional package unavailable: $p"; fi
   done;;
 esac
}
