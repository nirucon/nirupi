#!/usr/bin/env bash
packages(){
 # BASE = everything NIRU Noir needs to work after a clean install:
 #   X11 + build deps, terminals, launcher/status, notifications, screenshots,
 #   clipboard, wallpapers, idle/lock, night light, compositor, image tooling,
 #   NetworkManager (Wi-Fi menu + network segment), bluez (bluetooth segment),
 #   icon/emoji fonts and the Python/mpv stack used by the default ~/Git apps.
 case "$DISTRO" in
 arch|cachyos)
  PKGS=(base-devel git xorg-server xorg-xinit xorg-xsetroot xorg-xrandr xorg-xrdb xorg-setxkbmap xorg-xprop
   libx11 libxcb libxft libxinerama imlib2 fontconfig freetype2 pkgconf
   fish kitty feh dunst rofi alacritty pcmanfm arandr
   playerctl brightnessctl maim xclip libnotify flameshot
   pipewire wireplumber pipewire-pulse dbus glib2
   picom xss-lock gammastep imagemagick unzip zip xdotool xdg-utils
   xf86-input-libinput mesa sof-firmware alsa-ucm-conf pipewire-alsa
   man-db bash-completion xdg-desktop-portal xdg-desktop-portal-gtk noto-fonts
   networkmanager bluez-utils papirus-icon-theme noto-fonts-emoji nsxiv
   python python-pip mpv yt-dlp pacman-contrib curl jq gawk fzf util-linux)
  OPTIONAL_PKGS=(xautolock xidlehook redshift acl
   btop bat eza fd ripgrep zoxide fastfetch cava librespot
   gimp filezilla vlc cmus scrot p7zip unrar neovim micro meld
   gvfs udisks2 udiskie blueman lxappearance qt5ct qt6ct kvantum
   nextcloud-client flatpak pyside6 hunspell);;
 debian)
  PKGS=(build-essential git xorg xinit x11-xserver-utils x11-xkb-utils x11-utils
   libx11-dev libxcb1-dev libx11-xcb-dev libxcb-res0-dev libxft-dev libxinerama-dev
   libimlib2-dev libfontconfig1-dev libfreetype-dev pkg-config
   fish kitty feh dunst rofi alacritty pcmanfm arandr
   playerctl brightnessctl maim xclip libnotify-bin flameshot
   pipewire wireplumber pipewire-pulse dbus dbus-x11 libglib2.0-bin
   picom xss-lock gammastep imagemagick unzip zip xdotool xdg-utils
   xserver-xorg-input-libinput libgl1-mesa-dri alsa-ucm-conf pipewire-alsa
   man-db bash-completion xdg-desktop-portal xdg-desktop-portal-gtk fonts-noto-core
   network-manager bluez papirus-icon-theme fonts-noto-color-emoji sxiv
   python3 python3-pip python3-venv mpv yt-dlp curl jq gawk fzf util-linux)
  OPTIONAL_PKGS=(xautolock xidlehook redshift hunspell-sv
   btop bat eza fd-find ripgrep zoxide fastfetch cava librespot
   gimp filezilla vlc cmus scrot unrar-free p7zip-full neovim micro meld
   gvfs udisks2 udiskie blueman lxappearance qt5ct qt6ct kvantum
   nextcloud-desktop flatpak python3-pyside6.qtcore python3-pyside6.qtgui python3-pyside6.qtwidgets hunspell);;
 void)
  PKGS=(base-devel git xorg xinit xsetroot xrandr xrdb setxkbmap xprop
   libX11-devel libxcb-devel libXft-devel libXinerama-devel
   imlib2-devel fontconfig-devel freetype-devel pkg-config
   fish-shell kitty feh dunst rofi alacritty pcmanfm arandr
   playerctl brightnessctl maim xclip libnotify flameshot
   pipewire wireplumber dbus glib
   picom xss-lock gammastep ImageMagick unzip zip xdotool xdg-utils
   xf86-input-libinput mesa mesa-dri alsa-ucm-conf alsa-pipewire man-db
   bash-completion xdg-desktop-portal xdg-desktop-portal-gtk noto-fonts-ttf sof-firmware
   NetworkManager bluez papirus-icon-theme noto-fonts-emoji sxiv
   python3 python3-pip mpv yt-dlp curl jq gawk fzf util-linux)
  OPTIONAL_PKGS=(xautolock xidlehook redshift hunspell-sv
   btop bat eza fd ripgrep zoxide fastfetch cava librespot
   gimp filezilla vlc cmus scrot unrar p7zip neovim micro meld
   gvfs udisks2 udiskie blueman lxappearance qt5ct qt6ct kvantum
   nextcloud-client flatpak python3-pyside6 hunspell);;
 esac
 # Default profile keeps desktop install smaller; optional programs are inspected through doctor.
 if [[ $SESSION == sddm ]]; then
  case "$DISTRO" in
   arch|cachyos) PKGS+=(sddm qt6-declarative);;
   debian) PKGS+=(sddm qml6-module-qtquick qml6-module-qtquick-controls);;
   void) PKGS+=(sddm qt6-declarative);;
  esac
 fi
 # Vendor firmware/driver extras are best-effort (installed via the optional
 # pass), so a name that is unavailable on one distro can never abort a clean
 # install — it only produces a warning.
 detect_hardware_packages
}
# Detect CPU/GPU vendor and queue the matching microcode + VA-API/Vulkan bits.
# Mesa (OpenGL) is already in PKGS for every distro.
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
 case "$DISTRO" in
  arch|cachyos)
   [[ $cpu == intel ]] && OPTIONAL_PKGS+=(intel-ucode)
   [[ $cpu == amd ]] && OPTIONAL_PKGS+=(amd-ucode)
   case "$gpu" in
    intel) OPTIONAL_PKGS+=(vulkan-intel intel-media-driver);;
    amd)   OPTIONAL_PKGS+=(vulkan-radeon libva-mesa-driver);;
   esac;;
  debian)
   [[ $cpu == intel ]] && OPTIONAL_PKGS+=(intel-microcode)
   [[ $cpu == amd ]] && OPTIONAL_PKGS+=(amd64-microcode)
   case "$gpu" in
    intel) OPTIONAL_PKGS+=(mesa-vulkan-drivers intel-media-va-driver);;
    amd)   OPTIONAL_PKGS+=(mesa-vulkan-drivers mesa-va-drivers);;
   esac;;
  void)
   [[ $cpu == intel ]] && OPTIONAL_PKGS+=(intel-ucode)
   [[ $cpu == amd ]] && OPTIONAL_PKGS+=(amd-ucode)
   case "$gpu" in
    intel) OPTIONAL_PKGS+=(vulkan-intel intel-media-driver);;
    amd)   OPTIONAL_PKGS+=(vulkan-radeon mesa-va-driver);;
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
 log "Preparing ${#PKGS[@]} packages (Arch/CachyOS requires an approved full system upgrade)"
 case "$DISTRO" in
  arch|cachyos) # Arch requires coherent package databases. Never perform a silent partial upgrade.
  warn 'Arch/CachyOS: packages must be installed with a full synchronized upgrade to avoid partial upgrades.'
  printf 'Type UPGRADE to approve a full pacman system upgrade plus package installation: '
  read -r pacman_answer
  [[ $pacman_answer == UPGRADE ]] || die 'Pacman installation cancelled'
  sudo pacman -Sy --needed --noconfirm archlinux-keyring || warn 'keyring refresh failed (continuing)'
  sudo pacman -Syu --needed -- "${PKGS[@]}";;
  debian) sudo apt-get update && sudo apt-get install -- "${PKGS[@]}";;
  void) void_packages_preflight; sudo xbps-install -S -- "${PKGS[@]}";;
 esac
}
# Optional packages are best-effort: a missing name in one repo must never
# abort a clean install. Each package is probed before installation.
install_optional_packages(){
 ((${#OPTIONAL_PKGS[@]})) || return 0
 log "Installing ${#OPTIONAL_PKGS[@]} optional package(s) (best effort)"
 local pkg
 case "$DISTRO" in
  arch|cachyos)
   for pkg in "${OPTIONAL_PKGS[@]}"; do
    if sudo pacman -Si -- "$pkg" >/dev/null 2>&1; then
     sudo pacman -S --needed --noconfirm -- "$pkg" || warn "optional install failed: $pkg"
    else warn "optional package unavailable: $pkg"; fi
   done;;
  debian)
   for pkg in "${OPTIONAL_PKGS[@]}"; do
    if apt-cache show -- "$pkg" >/dev/null 2>&1; then
     sudo apt-get install -y -- "$pkg" || warn "optional install failed: $pkg"
    else warn "optional package unavailable: $pkg"; fi
   done;;
  void)
   for pkg in "${OPTIONAL_PKGS[@]}"; do
    if xbps-query -R "$pkg" >/dev/null 2>&1 || xbps-query -p pkgver "$pkg" >/dev/null 2>&1; then
     sudo xbps-install -Sy -- "$pkg" || warn "optional install failed: $pkg"
    else warn "optional package unavailable: $pkg"; fi
   done;;
 esac
}
