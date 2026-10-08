# First VM installation test

**Test only in a disposable VM snapshot.** These checks do not imply compatibility on physical machines.

1. Install a minimal **Debian 13** VM with a normal sudo-capable user, working network access and X11-compatible graphics.
2. Copy/extract the complete NIRUPI archive into the VM, run `./install.sh --plan`, `./install.sh --doctor`, and `./tests/smoke.sh`.
3. Read package list carefully. The package names are not fully verified on all target distributions.
4. Snapshot the VM. Run `./install.sh --apply --session sddm` in a **local interactive terminal** and review confirmations for SDDM and slock. Skip slock until a source/security review is complete.
5. Reboot and test SDDM's `NIRUPI DWM` session. Check login, Kitty, dmenu, wallpaper, statusbar, keybindings and exit. Use a VM console to recover from login loops.
6. Verify system-level side effects: `/usr/share/xsessions/nirupi-dwm.desktop`, `/usr/share/sddm/themes/niru-noir`, `/etc/sddm.conf.d/10-niru-noir.conf` and service state. Review `~/.local/state/nirupi/backups/` for backed-up user files.
7. Repeat with `--session startx` on a clean snapshot; `startx` should open the same runtime session. The installer deliberately preserves an existing `.xinitrc`.
8. Only then repeat against Arch, CachyOS and Void glibc. For Void, verify runit service activation manually.

## Required output when reporting failures

```sh
cat /etc/os-release
uname -m
./install.sh --plan
./install.sh --doctor
./tests/smoke.sh
```

Attach the failing command output plus `journalctl -b -u sddm --no-pager` on systemd or relevant runit SDDM logs on Void. Sanitize usernames, home paths and tokens before sharing.

## Open limitations

- Root/system rollback is manual.
- SDDM theme QML runtime has not been exercised.
- `slock` privileged execution requires audit; it is opt-in.
- Some upstream DWM shortcuts target optional tools not included in the package map.
- Wallpaper rotation requires `~/Pictures/Wallpapers` or `$WALLPAPER_DIR` containing images.
