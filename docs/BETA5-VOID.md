# NIRUPI 0.2.0-beta.5 — Void compatibility

- Correct XBPS package name: `fish-shell`, not `fish` (Debian/Arch remain unchanged).
- Read-only XBPS preflight checks repository or installed-package availability before package transactions and, for `--apply`, before snapshot creation.
- `nirupi doctor` reports Void runit/SDDM status without requiring root or assuming systemd; inability to read `sv status` is informational.
- `nirupi doctor` identifies the actual running DWM executable, distinguishing NIRUPI-managed from external DWM.
- `nirupi --version` and `nirupi -V` now alias `nirupi version`.
- README shortened and aligned with current beta.

Void hardware validation from beta.4: DWM ran from the NIRUPI versioned installation after reboot; the doctor baseline passed. **Beta.5 has not yet been installed on Void hardware.**

Installation remains an interactive local-TTY operation. This release does not enable runit services automatically or change existing GTK/DWM user configurations. Full system rollback is not provided.
