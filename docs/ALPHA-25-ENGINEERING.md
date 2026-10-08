# Alpha.25 — Pre-package local safety preflight

## Fix

The installer previously checked unmanaged DWM/dmenu/st executables and an unsafe custom DWM config **after** package installation. On a collision it would abort only after modifying the system. It now checks these before invoking the package manager. This also checks for symlinked checksum manifests.

## Validation

- Functional isolated-HOME tests for clean preflight, preserved custom config, foreign executable, unmanaged symlink, DWM config symlink and manifest symlink.
- Full existing smoke suite is run as an unprivileged user.

## Not yet verified

- Full Suckless compilation on Debian 13 or other target distros.
- Real DWM/SDDM session, statusbar rendering, font installation, and visual UX.
- System-wide rollback and complete GitHub source publication.

This is a pretest alpha. Do not install over a valuable desktop.
