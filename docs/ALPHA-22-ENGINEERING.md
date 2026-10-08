# NIRUPI alpha.22 — Executable managed-upgrade tests

- Extracted checksum-tracked helper deployment into `lib/managed.sh` for independent testing.
- Functional tests exercise new install, managed upgrade, changed permissions, user edits, foreign files, symlinks, backups and manifest uniqueness.
- Fixed `put_file` so equal-content files with incorrect permissions are repaired instead of silently skipped.
- Preserves legacy untracked helpers; migration requires a future explicit opt-in.

## Verification boundaries

This environment can generate Suckless Make commands but lacks Xft development headers, so full patched Suckless compilation is not yet verified. The X11 session, SDDM QML, package names, real font rendering and UI still require VM/hardware testing. The complete GitHub tree is not yet published.
