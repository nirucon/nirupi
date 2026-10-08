# Physical pilot checklist — NIRU Noir

## Before installation

- [ ] Disposable Debian 13 VM: `bash tests/smoke.sh` passes as a normal user.
- [ ] `bash tests/build-dependencies.sh` and `bash tests/compile-suckless.sh` pass.
- [ ] `bash install.sh --doctor`, `--plan` and `--audit` reviewed.
- [ ] Confirm keyboard layout, monitor resolution, GPU drivers, Xorg, Xft and fontconfig.
- [ ] Verify actual Nerd Font availability and Rofi theme parsing.
- [ ] Test install from a local TTY and verify package manager exits successfully.
- [ ] Test SDDM login/logout and startx fallback (on separate VM snapshots).
- [ ] Verify screenshot tools, lock screen, audio, clipboard, wallpaper, sleep, bar and dmenu shortcuts.
- [ ] Repeat installation with user-edited DWM config and dotfiles; verify preservation and build config.
- [ ] Test failure recovery from snapshot and inspect backup directory.
- [ ] Back up the physical target before touching it; have bootable rescue media.

## First boot smoke checks

- [ ] Log in; launch Kitty, dmenu and Rofi; change DWM layout and tags.
- [ ] Test multi-monitor, keybindings, screenshot, lock/unlock and logout.
- [ ] Inspect `journalctl -b` and Xorg/SDDM logs.
- [ ] Check RAM/CPU idle usage and statusbar process count.
- [ ] Reboot twice; verify consistent behavior.

Stop and report any unexpected file replacement, package conflict, black screen, or failed login. Do not promote to beta until VM checks pass.
