# NIRUPI alpha.14 — Desktop integration checkpoint

## Fixes
- Wallpaper startup now uses the same case-sensitive default path as the wallpaper daemon: `~/Pictures/Wallpapers`.
- `WALLPAPER_DIR` is honored consistently by session and daemon.
- DWM statusbar uses a non-blocking per-display `flock` lock to prevent duplicate writers.
- Empty kernel, host, weather, date and time segments are no longer inserted into the bar.
- Wallpaper daemon checks its `flock` dependency explicitly.
- New integration checks cover wallpaper path agreement and statusbar locking.

## Outstanding risks
- Full Suckless compilation and SDDM login not tested on a supported distro.
- Package maps, full keybindings, wallpaper behavior with multiple monitors, and rollback still need runtime verification.
- The statusbar remains a large inherited Bash script; module-level caching and benchmarks remain future work.
- Repository source tree must be published and a clean GitHub clone verified before using GitHub as an install source.
