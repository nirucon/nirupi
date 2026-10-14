# Changelog

All notable changes to NIRUPI. Versions are the `VERSION` file value.

## 0.5.0
- `nirupi gc` — prune old versioned binaries, release snapshots and backups
  (dry-run, `--yes`, `--legacy`).
- `nirupi update` — pull the source checkout and print upgrade steps.
- `nirupi status --once` / `--json` — bar rendered once as text or JSON.
- `./install.sh --adopt-dots` — force-adopt bundled dotfiles and the DWM config
  (previous files are backed up).
- Dynamic wallpaper palettes now enforce foreground/background contrast.
- `nirupi doctor` prints hints for missing idle-lock tool and NetworkManager.
- Tests: `nirupi gc` pruning, whitespace-safe statuscmd ids (bidirectional),
  bar auto-restart disabled in tests (`NIRUPI_NO_RESTART`).

## 0.4.18
- Fix: statuscmd section ids are raw bytes; ids 9–13 (tab/LF/VT/FF/CR) broke the
  status line (temperature id 10 = LF created an empty segment). Remapped to
  1–8 and 14–30.

## 0.4.17
- The status bar detects whether the running dwm supports status2d/statuscmd and
  falls back to a plain bar on older dwm (safe upgrades).

## 0.4.16
- `notify-send` usage fixed (`-a NIRUPI`).

## 0.4.15
- Click-info on every bar segment (battery, temp, memory, uptime, disk, cpu,
  load, bluetooth, kernel, host, date, time, media, now-playing, mic, DND,
  recording, network right-click = IP).

## 0.4.13
- Bar colour follows the theme mode live (colour only in wallpaper mode).

## 0.4.10
- `Super+Shift+h` (keybinding palette) and `Super+Shift+m` (control center),
  layout independent.

## 0.4.6
- Fix: statuscmd command path (`.sh`), working temperature (hwmon via glob).

## 0.4.0
- dwm 6.8 + slock 1.7; status2d, statuscmd (nosignal) and xresources patches.
- Noir Bar 2.0, opencode/agent, control center, keybinding palette, dynamic
  wallpaper theme, idle lock, dark icon theme, English strings.

## 0.3.0
- Non-destructive migration engine, three-way config merge, archived foreign
  binaries, unified rollback, custom_apps.conf, modular flags.
