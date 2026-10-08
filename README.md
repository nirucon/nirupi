# NIRUPI — NIRU Post Install

A personal, modular NIRU Noir / patched Suckless DWM desktop installer for Arch, CachyOS, Debian 13 and Void Linux (glibc).

**Current development version: 0.2.0-alpha.12 — PRETEST ONLY.**

> **Repository status:** The complete source tree has **not yet** been pushed to GitHub. This README is a progress record, not a working clone/install source. Do not run an installation from this repository until the full source is published and verified.

## Alpha.12 engineering work

- Build staging now runs inside a subshell with an EXIT cleanup trap.
- Preflight rejects unmanaged executable symlinks before compiling/deploying the desktop.
- Package installation messaging correctly distinguishes Arch/CachyOS full upgrades.
- Earlier alphas improved read-only diagnostics, helper deployment, dotfile preservation, package update reporting and file-safety tests.

## Target architecture

- Patched DWM, dmenu, st, slock.
- NIRU Noir look, NIRU SDDM theme by default; startx optional.
- Shared user-level helper scripts and dotfiles, distro-aware package installation.
- Explicit confirmations before privileged actions.

## First-test workflow

On a disposable Debian 13 installation, **using the complete source ZIP provided separately**:

```sh
./install.sh --plan
./install.sh --doctor
./install.sh --audit
./tests/smoke.sh
```

Do not run `--apply` on a valuable workstation. Complete package resolution, Suckless compilation, SDDM QML runtime, X11 login, and full rollback are **not yet verified on target distributions**.

## Roadmap

1. Audit and test all statusbar modules, desktop helpers, keybindings and dependencies.
2. Verify packages, builds and X11 login on Debian 13, Arch, CachyOS and Void glibc.
3. Add managed-file manifests, upgrade safety and tested rollback.
4. Publish and verify the **complete** source tree on GitHub.
5. Perform controlled laptop installation and fix integration issues before a stable release.

This project is tailored to a personal Linux setup, not a general-purpose supported distribution.
