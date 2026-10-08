# Alpha.21 — Configuration ownership and upgrade safety

## Fixed
- Existing `~/.config/suckless/dwm/config.h` is now preserved rather than overwritten on every install.
- Regular-file collisions at `~/.config/{kitty,fish,dunst,picom,rofi,alacritty,gtk-3.0,cmus}` are preserved rather than passed to `mkdir -p`.
- Existing `~/.local/bin/nirupi-session` is preserved (and symlinks/non-regular paths are refused), pending an ownership manifest.
- Added source-level regression tests.

## Tradeoff and follow-up
Preservation avoids losing user changes but means old managed configurations and sessions will not automatically update. A proper checksum manifest with explicit merge/replace confirmation is needed before claiming a seamless upgrade path. This is not yet implemented for these files.

## Outstanding
- Complete GitHub source tree publication and clean clone verification.
- Runtime compilation and graphical tests on Debian 13, Arch, CachyOS and Void glibc.
- Full DWM/dmenu, SDDM and NIRU Noir visual verification.
- System-wide rollback and package validation.
