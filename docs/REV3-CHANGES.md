# NIRUPI 0.2.0 PRETEST REV3 – audit and changes

This is a **pretest development snapshot**, not a cross-distro verified release.

## Improvements
- Added a preflight `doctor` command for common DWM keybinding dependencies.
- Added missing interactive desktop dependencies to package maps (unverified names on Void).
- Bundled the original `config.h` in the expected location for the keybindings helper.
- Added explicitly confirmed, privileged slock installation instead of silently treating a non-setuid home binary as a usable lock.
- Replaced in-place Suckless binary overwrite with unique run-ID versioned storage and atomic symlink replacement.
- Added directory collision protection before replacing managed files.
- Maintained read-only plan and opt-in SDDM setup; prevented SDDM auto-enable when another known DM is enabled.
- Do not launch wallpaper daemon when no wallpaper directory exists.

## Critical limitations
- Package names, Suckless build, greeter QML and login are **not tested** on actual Arch/CachyOS/Debian/Void VMs.
- `slock` setuid-root is a security-sensitive upstream design: inspect the source, review site policy, or skip locking until tested. Do not enable it on production before audit.
- Some DWM keybindings target optional tools (Helium, Brave, screenshot tools, audio, etc.). Not every binding is guaranteed.
- Only selected original look-and-feel helpers are installed. The vendor directory includes originals for manual audit; it is not an exhaustive postinstall migration.
- The installation is not transactional; package, SDDM and other system changes require manual rollback.
- Automatic GitHub source publication is separate from a local ZIP build; compare release checksums when uploading.
