# Alpha.21 — Configuration ownership and upgrade safety

## Fixed
- Existing `~/.config/suckless/dwm/config.h` is preserved instead of overwritten during installation.
- Regular-file collisions at `~/.config/{kitty,fish,dunst,picom,rofi,alacritty,gtk-3.0,cmus}` are preserved.
- Existing `~/.local/bin/nirupi-session` is preserved; symlinks/non-regular files are rejected.
- Added source-level regression tests.

## Tradeoff
Preservation protects personal customizations but also means old managed configs will not automatically update. A proper checksum manifest and user-approved migration are still required.

## Outstanding
- Publish full source tree and verify clean clone.
- Build/run patched Suckless tools and X11/SDDM on target distros.
- Verify font, theme and package dependencies, and system rollback.

This remains a pretest alpha.
