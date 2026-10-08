# NIRUPI 0.2.0-alpha.30 — Consolidated installation readiness

## Improvements since alpha.25

1. Added early checks for enabled GDM/LightDM/LXDM when SDDM is selected. These checks run **before package installation**.
2. Refuse symlink and file collisions along NIRUPI-controlled HOME and state directory paths before installation.
3. Added read-only build dependency inspection (`tests/build-dependencies.sh`).
4. Added actual non-installing Suckless compilation test (`tests/compile-suckless.sh`) using temporary copies of dwm/dmenu/st/slock. The script checks binaries and dmenu helper files.
5. Added isolated-HOME regression test for unsafe directory and manifest state paths.
6. Added a physical-installation checklist with exit criteria and recovery notes.

## Important blockers and honest test status

- **No complete Suckless build in this environment**: Xft, Xinerama, fontconfig and FreeType pkg-config dependencies are missing. Run the compile test on a disposable Debian 13 VM after installing build prerequisites.
- No complete Debian 13 VM install or actual SDDM/X11 login test has been performed.
- No verified rollback of packages, display-manager service changes or system-level files.
- Other distro package maps (Arch/CachyOS/Void) are not independently verified.
- Full source tree still must be published to GitHub and tested from a clean clone.

## Go/no-go for physical pilot

Before installing on physical hardware, require a successful fresh install, login/logout, restart, repeat install, build test, font test and recovery exercise in a disposable VM. Keep the old desktop or another TTY available for recovery. Do not enable SDDM over an existing display manager without explicit migration.

This release is **alpha**, not a production-certified or hardware-certified installer.
