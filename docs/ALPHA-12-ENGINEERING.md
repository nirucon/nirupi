# NIRUPI 0.2.0-alpha.12 — installation lifecycle audit

## Changes
- Run desktop deployment in a subshell with an EXIT trap to clean temporary build trees on failure or success.
- Preflight all managed executable symlinks before compilation and user deployment.
- Correct misleading package-installation log about Arch/CachyOS full upgrades.
- Keep existing user configuration preservation behavior; no unreviewed dotfile overwrites.

## Known blockers before hardware-ready release
- Test compilation and package resolution on Debian 13, Arch, CachyOS and Void glibc.
- Validate SDDM theme imports and session login on a disposable machine.
- Verify keyboard bindings, status modules, media controls, wallpaper, suspend and lock.
- Add manifest-driven upgrades, rollback and safe ownership of helper scripts.
- Publish the complete source tree, not only the README, to GitHub.

Static smoke checks do not establish working graphical sessions.
