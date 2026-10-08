# NIRUPI — NIRU Post Install

A lightweight, modular **NIRU Noir / Suckless DWM** desktop project targeting **Arch, CachyOS, Debian 13, and Void (glibc)** on x86_64.

> **Development status: 0.2.0 PRETEST REV3.** This is not verified for production. Real clean-install tests on all four distributions are still required.

## Design

- Preserve the existing customized DWM, dmenu, st, and slock sources and visual identity.
- Original **NIRU Noir SDDM** theme by default; `startx` is an option.
- A single repository with a modular shell installer and distro-specific package maps.
- Read-only plan, diagnostic checks, backups for modified user files and explicit system-change confirmation.
- Future support for separate NIRU applications (source currently remains in Nextcloud; not bundled here).

## Source availability

The complete `NIRUPI-0.2.0-PRETEST-REV3.zip` is currently provided through the project conversation; this GitHub repository is being initialized separately. **The full installer/vendor source tree has not yet been committed to this repository.** Do not clone this repository expecting a runnable `install.sh` until the source tree is uploaded and verified.

## Planned VM-only commands

```bash
./install.sh --plan
./install.sh --doctor
./tests/smoke.sh
# After snapshot and preflight checks, in a disposable X11 VM only:
./install.sh --apply --session sddm
```

The installer does not automatically upgrade the entire OS, and does not silently enable privileged `slock` or a display manager. See the included `docs/FIRST-VM-TEST.md` in the complete archive.

## Release criteria

A stable release requires package resolution, Suckless build, SDDM/X11 login, startx login, keybindings, statusbar, wallpaper, reinstallation and rollback validation on every supported distribution.
