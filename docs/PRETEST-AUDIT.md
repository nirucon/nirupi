# NIRUPI 0.2.0 – pre-test audit

This is an **uncertified pre-test build**, not a verified cross-distribution release.

## Corrections from the initial archive

- Removed implicit full-system upgrades from Arch/CachyOS and Void package actions.
- Made `--plan` read-only (no state directory created).
- Build all three Suckless binaries before replacing active binaries.
- Back up replaced user binaries and files; retain existing `~/.xinitrc`.
- Exclude maintenance, audio-tuning, and Ollama installation helpers from automatic deployment.
- Do not copy Fish's machine-specific `fish_variables`.
- Require a separate confirmation before changing SDDM theme/service state.
- Avoid duplicate Dunst instances; terminate session child processes when DWM exits.

## Known blocking gaps before calling this release verified

1. No live clean-install or login test on Arch, CachyOS, Debian or Void.
2. Package maps, SDDM QML dependencies and service activation must be checked in VMs.
3. DWM keybindings refer to `slock`, but it is not installed/configured; test locking before using a real workstation.
4. Legacy status bar is distro-specific and has hard-coded weather/media paths; refactor required.
5. Legacy wallpaper and keyboard helpers have not been behavior-tested.
6. Suckless build flags may need distro-specific correction.
7. No transactional rollback for system packages or SDDM service changes.
8. No comprehensive migration of old post-install scripts and no NIRU app recipe engine.
9. No reliable system-wide `doctor`, desktop smoke tests or CI matrix yet.
10. Display-manager conflicts, active user sessions and existing configurations need stronger preflight.

**First test:** use a disposable VM or snapshot. Run `./install.sh --plan` and `./install.sh --doctor` before any `--apply`.
