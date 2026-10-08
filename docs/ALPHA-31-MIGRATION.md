# Alpha.31 — Migration pilot

1. Make a separate machine-level backup or disk image.
2. Run `bash ./tests/smoke.sh` and `bash ./tests/compile-suckless.sh` (requires build dependencies).
3. Log into a local text TTY, not an X11 session or SSH.
4. Run `bash ./migrate-desktop.sh --plan` and review every path.
5. Run `bash ./migrate-desktop.sh --apply`; note the rollback ID.
6. Run `bash ./install.sh --doctor`, `--plan`, then `--apply` if checks pass.
7. Test startx/SDDM, DWM, dmenu, st, slock, Rofi, notifications, status, screenshots, sound, reboot and shutdown.

**Important:** Migration backup and rollback only cover existing selected user-level desktop files. System packages, system SDDM files, and newly installed user files are not reverted. Existing Fish config is intentionally excluded. Missing fonts, package availability and full Suckless builds remain verification gates.
