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
