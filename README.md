# NIRUPI — NIRU Post Install

Modular NIRU Noir / Suckless DWM desktop integration for Arch, CachyOS, Debian 13 and Void Linux (glibc).

**Latest local development artifact:** `0.2.0-alpha.5` — PRETEST ONLY.

> **Important:** This GitHub repository currently contains documentation, not the complete installer source. Do not expect `git clone` followed by `./install.sh` to work until the full source tree is published. The full alpha.5 ZIP is provided in the development conversation.

## Alpha.5 changes

- Corrected the update-count integration bug in `dwm-status.sh`.
- Reduced reliance on hardcoded executable paths and machine-specific media mount paths.
- Configurable status refresh interval, default 2 seconds.
- Added missing clipboard, screenshot, launcher and webapp helpers to deployment.
- Preserved existing per-file configuration during initial install.
- Added checks for directory collisions and regression tests.

## Intended first test

On a disposable Debian 13 installation with recovery media and no valuable data:

```sh
./install.sh --plan
./install.sh --doctor
./tests/smoke.sh
```

Do not run `--apply` on a production workstation. SDDM QML runtime dependencies, distro package maps, Void runit activation, and complete hardware installation remain unverified. The source archive includes `docs/ALPHA-5-AUDIT.md` for detailed limitations.

## Design

- Preserve original patched DWM, dmenu, st, slock and NIRU Noir look.
- NIRU SDDM default; `startx` optional.
- Shared modular installer with distro-specific package adapters.
- No automatic full OS upgrades, and no unapproved display manager or privileged `slock` changes.
- Future external NIRU app recipes without bundling their sources.
