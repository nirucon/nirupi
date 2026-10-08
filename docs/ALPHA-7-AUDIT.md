# NIRUPI 0.2.0-alpha.7 — source review and first hardware-test gate

## Scope of this review

Reviewed installer, package maps, DWM session, SDDM theme imports, deployed dotfiles and bundled helper inventory. This is a **source-level** review, not an end-to-end installation certification.

## Changes

- Arch/CachyOS: package installation now performs an **explicitly confirmed** coherent `pacman -Syu --needed`, avoiding the unsupported partial-upgrade approach. This is a full OS upgrade: take a snapshot and read pacman output before consenting.
- More user config included on clean installs: Alacritty, GTK3 and cmus; existing files are preserved.
- More conservative SSH detection and explicit required-command checks.
- Session wallpaper runner no longer assumes a wallpaper directory name that may differ from the script configuration.

## Significant remaining issues (must not be hidden)

1. `dwm-status.sh` is still a large inherited shell program, not fully modularized or profiled. Some Arch-specific branches remain; other distros require runtime checks.
2. `wallrotate.sh`, screenshot, clipboard, webapp, and keybinding helpers need interactive X11 smoke testing.
3. SDDM theme uses `SddmComponents 2.0` and custom QML; distro-specific greeter runtime and theme imports have not been tested.
4. The installer does not provide a transactional rollback for system packages, SDDM service state, or root-owned theme files.
5. The original Suckless code and patches have not been compiled on the four target distros.
6. Void runit SDDM service activation remains a manual step.
7. `slock` setuid-root must be explicitly reviewed on the test machine before enabling.
8. The installer preserves pre-existing config; consequently, an existing DWM machine may not match a clean install. This is intentional, not a completed migration feature.
9. The source tree still contains old helper scripts retained for provenance; they are not all installed or audited as safe to execute.
10. A complete distro-specific package name and X11/SDDM runtime compatibility matrix is not yet established.

## First physical test

Use a disposable Debian 13 laptop installation, backed up and with recovery media available. Run `--plan`, `--doctor`, `tests/preflight.sh`, and `tests/smoke.sh` first. Do not use the test machine for critical data. Do not assert support for a distro until an actual login and restart test has passed.
