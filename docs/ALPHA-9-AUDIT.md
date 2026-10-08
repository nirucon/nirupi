# NIRUPI 0.2.0-alpha.9 — Audit notes

## Changes

- The updates adapter always emits a numeric result when the Arch or Void query fails.
- The Void XBPS branch is checked before the Debian APT branch.
- Added isolated mock-based tests for two pending updates and failed update queries.
- The DWM session reports a missing executable instead of silently exiting.
- Removed a duplicate sleep/suspend helper deployment entry.
- Guarded an existing X session symlink against replacement.

## Outstanding high-priority blockers

1. **GitHub:** full source tree is not yet published to the repository.
2. **SDDM:** custom QML theme and actual login have not been verified on Debian, Arch, CachyOS, or Void.
3. **Suckless:** compilation against the target distro's headers has not been tested end-to-end.
4. **Privilege:** setuid slock requires a separate security audit before activation.
5. **Installer:** full rollback and atomic multi-step deployment are not implemented.
6. **Dependencies:** package names, optional helpers, and all dotfiles require testing on clean machines.

Use only on a disposable laptop/VM with backup, and run --plan, --doctor, --audit, preflight and smoke tests before --apply.
