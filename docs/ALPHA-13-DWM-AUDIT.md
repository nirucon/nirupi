# NIRUPI alpha.13 — DWM integration audit

## Corrected
- Super+Shift+Escape now calls the lock-before-suspend helper rather than systemctl directly (works toward Void runit compatibility).
- Removed the keybinding that spawned a second DWM instance without stopping the first; use a controlled logout/login for now.
- Fixed inaccurate comments for Super+Enter and layout keys.
- The keybinding viewer now uses Kitty, the preferred terminal, rather than depending on Alacritty.
- Shell-invoked helper paths use `$HOME` rather than a literal tilde in double-quoted shell commands.
- Added a DWM integration regression check.

## Still requires physical verification
- Build and launch patched DWM on each distro; verify patch-specific functions and EWMH behavior.
- Verify all keyboard and mouse bindings, monitor hotplug, status text updates and statusbar click actions.
- Verify the actual slock binary is safely installed and locking works before suspend.
- Confirm SDDM QML modules, theme and login; compare startx behavior.
- Review remaining hardcoded app launchers (Helium, Brave, PCManFM) and package dependencies.
- Validate statusbar process CPU usage and network/weather behavior under X11.
- Test rollback of privileged changes before production deployment.

## GitHub publishing
A GitHub README update does not publish the source. Verify that the full 0.2.0-alpha.13 source tree has been committed before using `git clone` as an installation path.
