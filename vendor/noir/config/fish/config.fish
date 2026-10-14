function fish_greeting
end

# Theme colours generated from the active palette (nirupi theme apply).
if test -r ~/.config/nirupi/theme/fish.fish
    source ~/.config/nirupi/theme/fish.fish
end

# CachyOS extras only where that config actually exists.
if test -r /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# Distro-aware system update helper (architecture-agnostic).
if command -sq paru
    function update --description "Update system and AUR"
        paru -Syu --skipreview
    end
else if command -sq pacman
    function update --description "Update system"
        sudo pacman -Syu
    end
else if command -sq apt
    function update --description "Update system"
        sudo apt update; and sudo apt upgrade
    end
else if command -sq xbps-install
    function update --description "Update system"
        sudo xbps-install -Su
    end
end
