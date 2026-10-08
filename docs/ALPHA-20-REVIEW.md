# NIRUPI alpha.20 — DWM shortcut dependency and screenshot safety audit

## Fixed
- Added `maim`, `xclip`, `flameshot` and desktop notifications to the Arch/CachyOS and Debian package profiles. **Void package mapping remains unverified and deliberately unchanged.**
- `--doctor` now reports missing optional shortcut dependencies, including browsers, Gimp, sxiv and slock.
- Screenshot-select temporary files now use an EXIT cleanup trap, including on cancellation and failure.
- Sanitized custom screenshot filenames to prevent path traversal and unsafe names.
- Added regression checks for dependency coverage and screenshot safety.

## Remaining blockers
- Resolve Void packages and all four Suckless builds in disposable target environments.
- Run graphical tests for DWM, dmenu, Rofi, screenshots, wallpaper, SDDM and slock.
- Finish a managed-file upgrade/rollback system and verify all dotfiles.
- Publish the **complete** GitHub tree and verify a clean clone. Current repository is not installable.
- Ensure Nerd Font availability and check SDDM QML imports.

This alpha is not certified for unattended or production installation.
