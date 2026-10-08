# 0.2.0-alpha.4 — pre-install review

## Changes
- Replaced the hard-coded per-user SDDM session desktop entry with a shared wrapper that resolves `$HOME` for the login user.
- Explicitly refuse `--apply` inside any active graphical session.
- Detect a busy Debian package manager before beginning.
- Clean temporary Suckless build trees on normal function return.
- Added regression checks and aligned the version string with SemVer prerelease conventions.

## Known limitations / blockers
- Full installation has **not** been verified on Arch, CachyOS, Debian, or Void.
- The SDDM QML theme may require distro-specific Qt modules.
- Slock privilege handling requires review on the target machine.
- `startx` does not modify an existing `.xinitrc`; manual integration may be necessary.
- User file backups do not constitute a complete system rollback.
- Optional scripts copied from the original Noir project have not all been functionally tested.
- Do not install on a production workstation. Use a clean, snapshotted VM or a disposable test laptop.
