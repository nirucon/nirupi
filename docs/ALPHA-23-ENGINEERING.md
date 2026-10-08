# Alpha.23 — Managed NIRU Noir configuration upgrades

- Added SHA-256 ownership tracking for DWM config, Rofi theme, per-app dotfiles, Xresources, and user X11 launchers.
- Tracked files update only when their contents still match the previous NIRUPI-installed checksum.
- Untracked, user-modified, and symlinked files are preserved.
- Existing managed files are backed up before replacement; executable permissions are repaired.
- Added functional tests with an isolated HOME covering installation, upgrade, backup, user edits, symlinks, untracked xinitrc, and mode repair.

## Limitations
- DWM is compiled from the bundled vendor config; user-edited config.h is preserved but not automatically compiled.
- Full rollback, system-level ownership, clean-clone GitHub publication, real X11/SDDM tests, and distro package verification are pending.
- This remains a pretest alpha; do not install over a valuable desktop.
