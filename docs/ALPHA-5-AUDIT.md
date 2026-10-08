# NIRUPI 0.2.0-alpha.5 — pre-hardware audit

## Scope

The six original archives and alpha.4 were used as baselines. This release preserves original patched Suckless source, SDDM QML, Noir configuration, and existing helper scripts. It does **not** claim that every original post-install feature has been ported or optimized. The original Debian, Arch and Void install scripts remain reference material; do not run them together with NIRUPI.

## Fixes

- Corrected a real update-count bug: `nirupi-updates` already returns a number; piping it through `wc -l` always returned 1.
- Avoided treating a failed Arch `checkupdates` command as an available update.
- Removed hardcoded absolute paths to several standard utilities in the status bar and removed machine-specific media mount defaults.
- Raised status-bar refresh interval to 2s (configurable with `NIRUPI_BAR_INTERVAL`), preserving all original display functions.
- Installed missing screenshot, clipboard, webapp and launcher scripts referenced by DWM bindings.
- Preserve individual existing application config files rather than skipping the whole config directory.
- Reject destination directories, including symlink-to-directory collisions, before atomic replacement.

## Known blockers before production

1. SDDM QML runtime dependencies and theme preview are unverified on all target distros.
2. Void runit SDDM activation requires manual verification.
3. Full package maps have not been resolved against live repositories for every distro.
4. `slock` requires an explicit setuid-root decision and security review.
5. Wallpaper, screenshot, clipboard, webapp and keybinding helpers retain legacy logic and have not all been exercised on real hardware.
6. No end-to-end clean install, X11 login, suspend/resume, dual-monitor or rollback test has passed on target hardware.
7. Full system rollback is not implemented; snapshots and disposable test systems are mandatory.

## Suggested first hardware test

Use a disposable Debian 13 laptop installation, without valuable data, with a known recovery path. First run `--plan`, `--doctor`, and `tests/smoke.sh` as the intended non-root user; inspect results before `--apply`. Avoid enabling SDDM until its dependencies are checked.
