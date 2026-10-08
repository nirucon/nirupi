# NIRUPI 0.2.0 pretest rev2 – engineering changes

This is **not a certified cross-distribution installer**. It is intended for inspection and disposable VM tests only.

## Changes

- Added slock to staged builds and installation.
- Added a read-only update-count adapter for pacman, apt and XBPS.
- Disabled the original personal weather coordinates by default.
- Preserved pre-existing Xresources and session desktop files.
- Improved display-manager conflict handling on systemd.
- Refused installation from SSH or an active Hyprland session.
- Added static checks for legacy helper scripts and slock.

## Unresolved before production

- Package names and complete dependency closure are not verified across all distributions.
- Suckless builds have not been tested on each target distribution.
- Void runit SDDM activation is still intentionally manual.
- Existing DWM statusbar, wallpaper and keybindings need end-to-end testing.
- The installer does not provide transactional rollback for packages or system files.
- SDDM theme QML dependency compatibility needs actual graphical testing.
- No unattended integration or VM clean-install matrix has passed.
- This release must not be described as production-ready.
