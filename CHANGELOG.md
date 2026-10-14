# Changelog

All notable changes to NIRUPI. Versions are the `VERSION` file value.

## 0.7.0
- **Lock screen clock**: `slock` now draws a minimal clock + date + hostname
  (Xft) over the blur, in the Noir palette.
- **Window switcher** (`Super+w`), **gaps toggle** (`Super+g`) and **real
  fullscreen** (`Super+Shift+e`).
- **Caffeine** (`Super+Shift+c`) keeps the screen awake; the bar shows a cup.
- **Focus / do-not-disturb** (`Super+Shift+d`).
- **Screen recording** (`Super+r`) to `~/Videos/Recordings` (ffmpeg x11grab /
  wf-recorder); the bar shows a recording dot.
- **Automatic clipboard history** (`nirupi-clipd.sh`); `Super+v` now shows real
  history.
- **Minimal volume/brightness/mic OSD** (`nirupi-osd.sh`).
- **Keyboard-layout** (`Super+Shift+l`) and **touchpad** (`Super+Shift+t`) toggles.
- **Day/night palette** (`nirupi-theme-auto.sh`, control center).
- **Quick launch** for `nirunote`/`nplay` (`Super+Shift+n`/`o`) and control-center
  entries for the three default repos.
- **Tailscale toggle** in the control center.
- No keybindings use function keys; all new bindings are letters (Swedish-safe)
  and collision-tested. `Super+Alt+k` lists every binding including tags.
- Docs: new `docs/FEATURES.md`; old roadmaps removed.

## 0.6.1
- Fix: rofi menus (control center, agent, keybindings, screenshots) rendered a
  dark list on a dark background because `element-text` inherited rofi's dark
  default foreground. The generated theme now sets `element-text`/`text-color`
  explicitly and is a complete theme.
- Fix: dmenu opened half above the top bar (bar padding). dmenu gains a vertical
  offset (`-y`, `dmenu.yoffset`) and dwm exports the bar height via
  `NIRUPI_DMENU_Y`, so every dmenu (and helper) opens just below the bar.
- Workspace icons changed to: browser, 3× AI agent, folder, 3× terminal, chat.
- Base install now ships everything the desktop needs: picom, xss-lock,
  gammastep (night light), ImageMagick, xdotool, xdg-utils, NetworkManager,
  bluez, Papirus + emoji fonts, Python/mpv/yt-dlp and nsxiv.
- `ensure_helium`: Helium is provisioned automatically (Debian apt repo, Arch
  AUR helper, otherwise the official binary tarball) so a browser always exists.
- Default repositories `nirupresence`, `nirunote` and `nplay` are cloned to
  `~/Git/` on install and updated on `--update-dots`.
- Extra optional apps added for a familiar setup (bat/eza/ripgrep/zoxide/cava/
  librespot/PySide6/nextcloud/GIMP/VLC/meld/…).
- Suspend (`Super+Shift+Esc`) now locks the screen, waits `SUSPEND_DELAY_SECONDS`
  (default 3s) and then suspends; unlocking during the wait cancels it. Fixed the
  liveness check that made suspend refuse to run (slock drops to an unprivileged
  user, so a signal-0 probe returned EPERM).

## 0.6.0
- dwm 6.8 bar/session patch set: statusallmons, barpadding (vertpad/sidepad),
  tagicons (Nerd glyphs), swallow (xcb-res), actualfullscreen (Super+F11),
  focusurgent (Super+Shift+u) and cyclelayouts (Super+Ctrl+,/.).
- Theme depth: `st`/`dmenu` read Xresources at runtime; rofi, dunst and the SDDM
  theme are generated from `tokens.env`; built-in palettes
  (`nirupi theme list|preview|set`); Noir slock colors and `nirupi lock`.
- Session effects: idle ladder (dim → lock → DPMS → suspend), lock on suspend,
  logout confirmation (`Super+Shift+q`) and night light (`Super+n`).
- Web apps: Helium-first launchers and `nirupi webapp add|list|remove`.
- Ops: GitHub Actions CI (smoke on Debian + Arch, shellcheck), `nirupi doctor
  --fix`, and scheduled backups (`nirupi backup --schedule`).
- Docs: generated `docs/KEYBINDINGS.md`, optional whiptail installer TUI.
- Dependencies: libxcb/libx11-xcb/libxcb-res (swallow), gammastep/redshift,
  xss-lock added to install sets.

## 0.5.1
- `nirupi gc`: version directories referenced by retained release snapshots are
  never removed, so `nirupi rollback` keeps working.

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
