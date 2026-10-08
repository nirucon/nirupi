# NIRUPI — NIRU Post Install

A modular, lightweight NIRU Noir / Suckless DWM post-install project targeting **Arch, CachyOS, Debian 13, and Void Linux (glibc)**.

**Current development artifact:** `0.2.0-alpha.4` (pretest). **Not yet verified for a complete installation on any of the four distributions.**

The full source archive is available from the development conversation. **This GitHub repository currently contains documentation only, not the installer tree.** Do not clone it expecting `install.sh` to be present until the full source has been pushed.

## Publish the source archive from your machine

Download and extract `NIRUPI-0.2.0-alpha.4.zip` first. From inside the extracted `nirupi-0.2.0-alpha.4` directory:

```sh
git init -b main
git remote add origin https://github.com/nirucon/nirupi.git
git fetch origin main
git add -A
git commit -m 'feat: NIRUPI 0.2.0-alpha.4 pretest source'
git pull --rebase origin main
git push -u origin main
```

Review `git status` and `git diff` before pushing. The source includes original bundled Suckless and theme assets; check their license files before publishing. The alpha installer must only be run on a disposable, backed-up machine.

## Goals

- Keep the original NIRU Noir look and custom DWM/dmenu/st/slock patches.
- SDDM with custom theme by default; `startx` optional.
- Distro-specific package handling without silent full OS upgrades.
- Read-only installation plan, diagnostic checks and guarded configuration changes.
- Future external NIRU app recipes; the apps themselves remain outside this repository.

See the source archive's `docs/FIRST-VM-TEST.md` and `docs/ALPHA-4-CHANGES.md` before attempting an install.
