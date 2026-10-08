# NIRUPI 0.2.0-alpha.19 — Rofi theme integration and font diagnostics

## Corrected

- Rofi's `config.rasi` referenced `~/.local/share/rofi/themes/Black-Metal.rasi`, but the installer never deployed that file. The installer now copies the bundled theme before user configs.
- An existing Rofi theme is preserved, including symlinks; no silent overwrite of user customizations.
- `--doctor` reports the actual fontconfig match for JetBrainsMono Nerd Font instead of assuming the preferred font is installed.
- Added `tests/rofi-integration.sh` and included it in the smoke suite.

## Remaining engineering work

1. Check and install font dependencies consistently across all four distros (or ship a license-compliant fallback).
2. Verify Rofi theme parsing with Rofi installed and the patched DWM keybindings in a real X11 session.
3. Audit remaining keybindings for programs absent from the package lists.
4. Verify full Suckless compilation and SDDM QML theme runtime on Debian 13.
5. Complete manifest-driven upgrades, rollback and full GitHub tree publication.

The source ZIP is a **pretest alpha**, not a verified install on real hardware.
