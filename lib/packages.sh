#!/usr/bin/env bash
packages(){
 case "$DISTRO" in
 arch|cachyos) PKGS=(base-devel git xorg-server xorg-xinit xorg-xsetroot xorg-xrandr xorg-xrdb xorg-setxkbmap libx11 libxft libxinerama imlib2 fontconfig freetype2 pkgconf fish kitty feh dunst xorg-xauth libxext libxrandr libxcrypt curl jq gawk fzf util-linux rofi alacritty pcmanfm arandr playerctl brightnessctl maim xclip libnotify flameshot pipewire wireplumber pipewire-pulse);;
 debian) PKGS=(build-essential git xorg xinit x11-xserver-utils x11-xkb-utils libx11-dev libxft-dev libxinerama-dev libimlib2-dev libfontconfig1-dev libfreetype-dev pkg-config fish kitty feh dunst xauth libxext-dev libxrandr-dev libcrypt-dev curl jq gawk fzf util-linux rofi alacritty pcmanfm arandr playerctl brightnessctl maim xclip libnotify-bin flameshot pipewire wireplumber pipewire-pulse);;
 void) PKGS=(base-devel git xorg xinit xsetroot xrandr xrdb setxkbmap libX11-devel libXft-devel libXinerama-devel imlib2-devel fontconfig-devel freetype-devel pkg-config fish kitty feh dunst xauth libXext-devel libXrandr-devel libxcrypt-devel curl jq gawk fzf util-linux rofi alacritty pcmanfm arandr playerctl brightnessctl pipewire wireplumber);;
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
  void) sudo xbps-install -S -- "${PKGS[@]}";;
 esac
}
