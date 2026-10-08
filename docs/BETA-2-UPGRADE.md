# NIRUPI 0.2.0-beta.2 – controlled upgrade

Reference: working beta.1 on INGWAZ (Debian 13). Do not replace system DWM or user-edited configuration.

## Changes

- Package update cache invalidated when local package DB changes, or with `nirupi updates --refresh`.
- User-owned `~/.config/nirupi/status.conf` created only when absent.
- `nirupi` CLI: `doctor`, `status`, `updates`, `config`, `version`, `keys`.
- beta.1 `nirupi-updates` is migrated only if its checksum matches the bundled beta.1 baseline. Modified files are preserved.
- Binary-link snapshots remain limited to six executables. There is **no** full configuration/system rollback.

## Debian verification

From a graphical session or SSH: `bash ./tests/smoke.sh`, `bash ./install.sh --verify`, `bash ./install.sh --plan --session sddm`.

From a **local TTY** with DWM logged out: `bash ./install.sh --apply --session sddm`. Confirm each interactive prompt carefully. Afterward: `bash ./install.sh --verify`, `bash ./install.sh --history`, `~/.local/bin/nirupi doctor`.

Then log in via SDDM and verify DWM, Rofi, Kitty, statusbar and update refresh. Keep beta.1 snapshot; do not test rollback on a working host without a recovery plan.

## Void and Arch sequence

After Debian validation, run `--plan`, smoke tests, dependency checks and an inventory of existing display managers/window managers on Void. Confirm whether Void uses glibc, and which service manager and login manager are active. Never overwrite an existing desktop/session automatically. Repeat on Arch only after Void results are reviewed. Arch package operations may perform a full system upgrade and require explicit approval.
