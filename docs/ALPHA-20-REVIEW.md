# NIRUPI alpha.20 — DWM shortcut dependency and screenshot safety audit

## Fixed
- Added maim, xclip, flameshot and desktop notifications to the Arch/CachyOS and Debian package profiles. Void mapping is not yet verified and remains unchanged.
- --doctor now reports missing optional shortcut dependencies: browsers, Gimp, sxiv and slock.
- Screenshot-select uses EXIT cleanup for temporary files.
- Sanitized user-supplied screenshot filenames against traversal and unsafe names.
- Added regression checks for dependency coverage and screenshot safety.

## Remaining blockers
- Resolve Void package names and build patched Suckless on each target distribution.
- Test DWM, dmenu, Rofi, screenshots, wallpaper, SDDM and slock in a real X11 session.
- Complete managed-file upgrade and rollback.
- Publish the complete GitHub source tree and verify a clean clone. This repository is not installable yet.
- Ensure Nerd Font availability and validate SDDM QML imports.

Pretest alpha; not certified for unattended or production installation.
