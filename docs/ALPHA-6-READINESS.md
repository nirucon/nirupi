# NIRUPI 0.2.0-alpha.6 — Hardware readiness review

## Changes
- Added a read-only asset/syntax preflight before package mutation.
- Protects user-installed helper scripts rather than overwriting them.
- Refuses replacing arbitrary existing non-symlink binaries with managed links.
- Protects symlink destinations during regular file deployment.
- Adds explicit acknowledgement of Arch/CachyOS partial-upgrade risk.
- Guards against duplicate status loop in the X11 session.

## Known limitations (not yet verified)
- Complete X11/SDDM login on Debian, Arch, CachyOS or Void.
- Actual package resolution and clean build on each distribution.
- SDDM QML modules and Void runit service activation.
- Full restore/rollback for system-wide changes.
- Feature parity for all historical scripts, themes and customizations.
- Security audit of bundled upstream patches and privileged slock.

## Safe first test
Use a disposable Debian 13 laptop with a full backup and TTY access.
Run `./install.sh --plan`, `./install.sh --doctor`, `./tests/preflight.sh`,
`./tests/smoke.sh`. Capture output and inspect the package plan before `--apply`.
Do not confuse static tests with verified hardware compatibility.
