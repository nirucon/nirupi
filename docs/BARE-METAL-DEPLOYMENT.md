# NIRUPI alpha.32 — bare-metal deployment gate

This is a test release. It has **not** passed a real Debian 13 X11 login or end-to-end rollback test.

## Phase 1: Read-only diagnostics (current old DWM session is fine)

```bash
bash ./tests/smoke.sh
bash ./tests/bare-metal-readiness.sh
bash ./install.sh --doctor
bash ./install.sh --plan --session sddm
bash ./migrate-desktop.sh --plan
```

## Phase 2: Build without installation

On Debian 13 install build dependencies (review apt transaction first):

```bash
sudo apt-get update
sudo apt-get install build-essential pkg-config libx11-dev libxft-dev libxinerama-dev libfontconfig1-dev libfreetype-dev libimlib2-dev libxext-dev libxrandr-dev libcrypt-dev
bash ./tests/compile-suckless.sh
```

Do not proceed if compilation fails. Note: package names and versions must be confirmed against the target host.

## Phase 3: Snapshot and migration

Before changing the old DWM desktop, make a filesystem/system backup or snapshot. NIRUPI's migration rollback only restores selected user files; it does not undo apt transactions, system display-manager changes, new helper files or other NIRUPI-managed files.

Use a local text TTY (Ctrl+Alt+F3) after logging out of X11. Confirm you have sudo access. Keep an emergency TTY available.

```bash
bash ./migrate-desktop.sh --plan
bash ./migrate-desktop.sh --apply
bash ./install.sh --plan --session sddm
bash ./install.sh --apply --session sddm
bash ./tests/post-install-verify.sh
```

The migration prints a backup ID. Record it before continuing. If installation fails, inspect logs and restore files with `bash ./migrate-desktop.sh --rollback BACKUP_ID`; package and system changes must be reverted separately.

## Phase 4: Login and hardware acceptance

Verify SDDM lists NIRUPI DWM and a session starts. Check terminal, dmenu, status, font rendering, wallpaper, keyboard shortcuts, clipboard, audio, screenshot, lock, logout, restart, power management, multi-monitor if relevant, and a second reboot. Keep the old Debian installation until the new session passes these tests.

## Release gate

Only mark production-ready after the above steps pass on actual target hardware and full restore/recovery has been tested. Publishing the full source tree to GitHub is also pending.
