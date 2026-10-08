# NIRUPI 0.2.0-alpha.8 — Pre-hardware audit

## Changed

- Added `--audit` for a read-only machine/environment report.
- Included the previously omitted `sleep-suspend.sh` in deployment.
- Replaced systemd-only suspend with a `loginctl`/`zzz` fallback and refuse suspend if `slock` is absent or exits immediately. **This is not a security guarantee**: a successful process check does not prove the display is locked; hardware tests are mandatory.
- Added explicit checks for existing non-symlink executables before NIRUPI link deployment.
- Checked extra installer dependencies before package changes.

## Remaining blockers

1. No clean end-to-end installation has been run on Debian 13, Arch, CachyOS or Void.
2. `slock` setuid security, SDDM theme/QML compatibility and X11 session startup remain unverified.
3. Existing helper scripts retain distro- and machine-specific assumptions; optional legacy installers are bundled but not executed.
4. Package resolution and runtime dependencies require real distro tests.
5. No transactional rollback for root-owned files, system services or package upgrades.
6. `sleep-suspend.sh` cannot prove lock readiness and must be tested before use; do not rely on it to protect sensitive sessions.
7. Existing dotfiles are preserved, so existing machines may require manual merges.

**This is a test candidate only. Do not claim production readiness.**
