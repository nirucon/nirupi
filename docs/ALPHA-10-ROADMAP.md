# NIRUPI 0.2.0-alpha.10 — engineering checkpoint

## Changes
- Refuse to overwrite existing symlinks unless they point to a NIRUPI-managed binary.
- Require `pkg-config` after package installation before compiling Suckless.
- Display explicit login-manager choice in installation plan.
- Add a wallpaper-directory gate to session startup.
- Extend smoke tests to guard against unmanaged symlink replacement.

## Important limitations
This release is **not validated on real hardware**. Tests here cover syntax, bundled assets,
read-only planning and simulated package-count behavior, not SDDM login or graphical function.

## Next roadmap milestones
1. Resolve all package names on Debian 13, Arch, CachyOS and Void glibc in disposable installations.
2. Build and run the original patched DWM/dmenu/st/slock on each target distro.
3. Test SDDM QML theme and startx login independently, including recovery after failure.
4. Test each keybinding, bar module, wallpaper, suspend, audio, screenshot and clipboard workflow.
5. Implement a manifest-driven upgrade path and a tested rollback of managed user/system files.
6. Publish the entire source tree to GitHub and verify clean clone + checksum.
7. Only then perform the first dedicated laptop installation.

Do not use on an important workstation. Use a backup or a replaceable OS install.
