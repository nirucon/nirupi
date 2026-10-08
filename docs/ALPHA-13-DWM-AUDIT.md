# NIRUPI alpha.13 — DWM integration audit

## Corrected
- Super+Shift+Escape invokes the lock-before-suspend helper instead of systemctl directly.
- Removed the unsafe DWM restart shortcut that spawned a competing window manager.
- Corrected misleading shortcut/layout comments.
- Keybinding viewer uses Kitty.
- Shell helper commands use $HOME instead of an unreliable quoted tilde.
- Added integration regression tests.

## Outstanding verification
- Build patched DWM on all supported distributions.
- Test every shortcut, mouse binding, monitor behavior and statusbar click.
- Test actual slock and suspend behavior.
- Validate SDDM theme and startx login.
- Validate runtime dependencies and package mappings.
- Benchmark statusbar and confirm safe system rollback.

The repository is not installable until the complete source tree is published and verified.
