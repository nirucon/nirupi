# Alpha.16 — DWM desktop integration and upgrade-safety review

## Fixed
- DWM and DISPLAY are validated before starting statusbar, wallpaper or notification daemons.
- Added a functional session-startup regression test (missing DWM and missing DISPLAY).
- New installations record SHA-256 hashes for managed helper scripts.
- Later installs update a helper only if its on-disk checksum matches the last NIRUPI-installed version.
- User-modified scripts, foreign symlinks and untracked scripts from earlier releases remain untouched.
- All managed helper replacements use existing backup and atomic-file-write logic.

## Deliberate limitations
- Pre-alpha.16 helper files have no trustworthy ownership manifest. They will be preserved; users must migrate them manually after reviewing differences.
- The manifest tracks helper scripts only. Dotfiles, binaries, SDDM and system files do not yet have a complete transactional ownership model.
- The manifest update is not a multi-file transaction. Interrupted installs may need manual recovery from backups.
- No target-distro X11 session or Suckless build has been validated here.
- GitHub remains incomplete until the entire source tree has been pushed and a clean clone tested.

## Next steps
1. Add automated manifest behavior tests, including user-edited and untracked helper preservation.
2. Audit and test every DWM keybinding against installed package maps.
3. Validate package resolution and actual builds in disposable distro images.
4. Publish all sources to GitHub and verify clean-clone reproducibility.
5. Test SDDM and startx, including logout, lock, suspend, wallpaper and bar.
