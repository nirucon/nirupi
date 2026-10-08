# Alpha.16 — DWM desktop integration and upgrade-safety review

## Changes
- Validate DISPLAY and the installed DWM executable before launching any session daemons.
- Add functional regression checks for missing DISPLAY and missing DWM.
- Track SHA-256 checksums for helper scripts installed by NIRUPI.
- Upgrade helpers only when their current checksum matches the recorded NIRUPI-managed version.
- Preserve user-modified, untracked legacy and foreign-symlink helpers.
- Use existing backup and atomic replacement when updating managed helpers.

## Limitations
- Existing alpha.15 and earlier helpers have no ownership manifest and are deliberately preserved.
- The manifest covers helpers, not dotfiles, SDDM, binaries or full rollback.
- Package maps, Suckless compilation and X11 runtime have not been validated on all target distros.
- **The complete source tree is not yet on GitHub**; a clone is not installable.

## Next
1. Test checksum-based upgrade scenarios and user modifications.
2. Verify every DWM/dmenu shortcut and installed dependency.
3. Build and run patched Suckless tools on Debian 13, then other distros.
4. Publish and verify the full source tree.
