# Changelog

All notable changes to NIRUPI. Versions are the `VERSION` file value.

## 0.9.2
- `nirupi gc` now also preserves any version directory that an installed
  symlink in `~/.local/bin` still points at, so pruning can never leave `dwm`,
  `dmenu` or `st` dangling (for example after only dwm was rebuilt). Covered by
  a regression test.
- Documentation refreshed for the new themes and the picker (README, USAGE,
  FEATURES, TEST-CHECKLIST).

## 0.9.1
- Identify a pre-0.8 `tokens.env` (which has no `NOIR_THEME_NAME`) by its
  background colour, so `nirupi theme list`/`status` report the real active
  theme and the picker marks the right row. A leftover `warm` palette, for
  example, now shows as **Noir warm** instead of the misleading default.

## 0.9.0
- **Two new themes: Hackerman** (phosphor green on black, CRT hacker look) and
  **Nord dark** (the Nord palette: Polar Night, frost and aurora accents).
- **Satie redesigned** to be genuinely monochrome — flat graphite with a single
  muted-gold accent — and noticeably lighter than Noir, so the two are easy to
  tell apart (they used to be nearly identical).
- **Carl Larsson** normal ANSI colours lifted for legibility (red/purple/blue
  were below 4.5:1 on the background).
- The theme picker and `nirupi theme list` now **include the Noir warm/cool
  variants** (they were hidden), and show the active theme plus a one-line
  description for every entry.
- Switching a theme shows a desktop notification with the new name.
- Removed the redundant static rofi theme install: it was immediately
  overwritten by the generated one and doubled the backups on every apply.
- Docs updated (README / USAGE / FEATURES).

## 0.8.1
- **Fix:** `nirupi theme set|apply|menu` (and therefore the `Super+Ctrl+t` picker)
  aborted partway on an installed system with `BACKUP_DIR: unbound variable`:
  the maintenance entry point sources the library without the installer's
  per-run backup directory. The library now derives a timestamped one lazily, so
  a live theme switch writes every fragment and restyles every app.
- **Fix:** the theme picker's default row (`Noir`) did not resolve, so choosing
  the default from the menu failed with `Unknown theme: Noir`. Theme names now
  match stems, display names and aliases case-insensitively, treating spaces and
  hyphens as equivalent (`Noir`, `noir`, `Noir warm`, `Carl Larsson`, …).
- **Fix:** the generated lazygit config is now merged through the managed-config
  path, so a hand-edited `~/.config/lazygit/config.yml` is preserved (with a
  `*.nirupi-new` proposal) instead of being overwritten without a backup.
- **Fix:** bump the DWM config schema to `v3`. A stale `config.h` (older schema)
  is now detected by version and the bundled config is compiled instead, so the
  new `Super+Ctrl+t` theme keybinding actually reaches the running DWM without
  silently building the old keymap. The user's file is preserved as
  `config.h.nirupi-new`. `nirupi migrate dwm --rebuild` applies the same check.
- **Dunst** now follows the theme without touching your settings: the colours
  (and font) are generated into `~/.config/dunst/dunstrc.d/90-nirupi.conf`, a
  dunst drop-in (dunst ≥ 1.8) that outranks the base `dunstrc`. Your padding,
  stacking and icon preferences are preserved; the bundled `dunstrc` is
  settings-only and deployed as the base.
- **Fix:** the `Super+Alt+k` keybinding viewer now describes every binding —
  it reads the `/* key -> text */` comments from `config.h` (so it never drifts)
  and has labels for the named launchers, instead of showing raw C variable
  names like `thememenu` or `agentcmd`. Media keys show `(none)` as the
  modifier and `` ` ``/`/` decode correctly. `docs/USAGE.md` and
  `docs/FEATURES.md` updated for the drop-in and the picker.
- **CI:** the Arch container job installs `diffutils`, so `tests/features-v07.sh`
  (and `cmp`-based checks) no longer fail with `diff: command not found`. The
  Arch smoke job had been red on every push because the minimal container lacked
  `diff`/`cmp`.

## 0.8.0
- **Multiple themes with a picker.** The whole desktop is generated from a single
  palette, so switching a theme restyles terminals (kitty, alacritty, st), fish,
  TUI tools (tmux, lazygit, micro, aerc, cmus), GTK/Qt, rofi, dunst, the SDDM
  theme and the status-bar accents — live, without a rebuild.
- New shipped themes: **Satie** (monochrome graphite, one muted-gold accent) and
  **Carl Larsson** (warm umber and watercolour accents), alongside **Noir** and
  the `warm`/`cool` variants.
- **Theme picker** on `Super+Ctrl+t` (`nirupi theme menu`): rofi with colour
  swatches. Also in the control center (`Theme: choose…`) and the key palette.
- `nirupi theme list|preview NAME|set NAME` (the old `set PALETTE` still works);
  add your own theme by dropping `Name.env` in `vendor/noir/theme/`.
- App colour configs (kitty/alacritty/tmux/fish/lazygit/micro/aerc/cmus) now
  *include* generated fragments instead of hard-coding Noir, so palette changes
  actually reach every app. Stale `docs/TESTING.md` removed.

## 0.7.2
- **Screensaver**: the clock is now always normal digits — only the **hostname**
  alternates between Elder Futhark runes and ASCII every 30 s. The first input
  switches to the **blurred desktop lock** (clock + ISO date + hostname + AFK),
  not a black screen.
- **Calendar**: clicking the date in the status bar opens a centred floating TUI
  (Swedish, Monday–Sunday, ISO week numbers; navigate months/years, `t` today).
- **System update**: clicking the updates segment opens the distro's updater in a
  centred floating terminal (apt / xbps / pacman). Also in the control center.
- The bar **agent icon** now uses the same robot glyph as the AI workspace tag.
- Control center: added **Calendar** and **System update**.

## 0.7.1
- **Power menu** on `Super+Shift+q`: screensaver, lock, suspend/logout/reboot/
  shut down, each with optional 15/30/60-minute (or custom) timers and a cancel
  option. Distro-portable (`loginctl` → `systemctl` → `sudo`).
- **Noir screensaver** on `Super+x` (and in the power menu): pure black with the
  clock and hostname in **Elder Futhark runes**, alternating with ASCII every
  30 s; the first key/click locks with slock. Runs only when invoked (never
  automatic). Bundles Noto Sans Runic so runes render everywhere.
- **Lock screen** (`slock`) now shows an ISO date (`2026-10-14`), the clock, the
  hostname and an **AFK timer**; no weekday/month. The screensaver blurs nothing.
- **Night light** (`Super+n`) cycles 4500 → 3500 → 2500 K → off, plus a direct
  off/reset. Toggling can no longer stack (kills the shifter and resets gamma).
- **Weather** is now the current temperature (Open-Meteo `current`), refreshed
  every 15 minutes; clicking opens **SMHI for Ljungskile** instead of Yr.
- `nplay` and `nirupresence` (terminal UIs) open inside kitty.
- Clipboard history cap unified (40) and the menu shows the last 12.

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
