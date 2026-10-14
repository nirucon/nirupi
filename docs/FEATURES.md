# NIRUPI features (NIRU Noir)

Every feature is opt-in/quiet and keyboard-first. `Super` is the Mod4/Win key.
All bindings use letters (safe on a Swedish layout) — **no function keys**.
The full list lives in [`KEYBINDINGS.md`](KEYBINDINGS.md) and on screen with
`Super+Alt+k` (the viewer also lists every tag binding).

## Desktop & window management (dwm 6.8)
- Right/left stack, floating, monocle, centered master / centered floating master;
  `Super+Ctrl+,`/`.` cycles layouts.
- **Window switcher** — `Super+w` opens `rofi -show window`.
- **Gaps toggle** — `Super+g` collapses/restores the window gaps.
- **Fullscreen** — `Super+Shift+e`.
- **Urgent jump** — `Super+Shift+u`.
- **Screen-on-all-monitors** status bar, per-monitor tags, bar padding.
- **Terminal swallow** — a terminal swallows windows it spawns.
- Scratchpad (`Super+Shift+s`), zoom (`Super+Shift+z`), bar toggle (`Super+Ctrl+b`).

## Lock screen (`slock`)
- `Super+Esc` locks immediately. The screen is blurred and shows an ISO **date**
  (`2026-10-14`), the **clock**, the **hostname** and an **AFK timer** (how long
  the lock has been up), in the Noir palette (`clockfont` etc. in
  `vendor/suckless/slock/config.h`).
- **Suspend** `Super+Shift+Esc` locks, waits `SUSPEND_DELAY_SECONDS` (default 3)
  and then suspends; unlocking during the wait cancels it.
- `nirupi lock` is the same wrapper.

## Screensaver (`slock -s`)
- `Super+x` (and the power menu) shows a **pure-black** screensaver with the
  clock and hostname in **Elder Futhark runes**, alternating with uppercase
  ASCII every 30 seconds — so it feels alive. **Never automatic.**
- The first key press or click locks the screen (you must then type your
  password). Bundles `Noto Sans Runic` (OFL) so the runes always render; it
  falls back to ASCII if the font is missing.
- Tune in `vendor/suckless/slock/config.h` (`runefont`, `clockforeground`).

## Power menu (`Super+Shift+q`)
- Screensaver · Lock · **Suspend** (now / 15 / 30 / 60 min / custom) ·
  Log out · **Reboot** (now / 15 / 30 / 60 / custom) · **Shut down**
  (now / 15 / 30 / 60 / custom) · Cancel · Cancel scheduled.
- Portable across Debian/Arch/Void via `loginctl` → `systemctl` → `sudo`.

## Focus & presence
- **Caffeine** `Super+Shift+c` — keeps the screen awake (no idle lock/DPMS) until
  toggled off. A small cup glyph appears in the bar while active.
- **Focus / do-not-disturb** `Super+Shift+d` — pauses notifications (`dunstctl`).
- **Night light** `Super+n` — cycles **4500 → 3500 → 2500 K → off** (via
  `gammastep`/`redshift`). `nirupi-nightlight.sh off|reset` turns it off and
  resets gamma; toggling never stacks.
- **Weather** — current temperature, refreshed every 15 minutes; clicking the
  segment opens **SMHI for Ljungskile**.

## Media & indicators
- **Volume / brightness / mic** hardware keys show a minimal monochrome OSD bar
  (`nirupi-osd.sh`), one reusable notification instead of a stack.
- **Screen recording** `Super+r` — toggles ffmpeg `x11grab` (X11) or `wf-recorder`
  (Wayland) to `~/Videos/Recordings`; the bar shows a red dot while recording.

## Clipboard
- **Automatic history** (`nirupi-clipd.sh`, started by the session) records text
  clipboard changes to `~/.cache/clip-text.log`.
- `Super+v` opens the clipboard/screenshot menu; `Super+Shift+v` saves the current
  selection manually.

## Input devices
- **Keyboard layout** `Super+Shift+l` — toggles Swedish/US (`nirupi-keyboard.sh`).
- **Touchpad** `Super+Shift+t` — toggles the touchpad via `xinput`.

## Theme
- Palettes: `nirupi theme list`, `nirupi theme preview NAME`,
  `nirupi theme set noir|warm|cool`.
- **Day/night auto** — `nirupi-theme-auto.sh auto` picks `warm` after 20:00 and
  before 07:00, else `noir` (also in the control center). Schedule it with cron,
  e.g. `0 * * * * ~/.local/bin/nirupi-theme-auto.sh auto`.
- Wallpaper-driven palette: `nirupi theme wallpaper IMAGE`.
- `st`/`dmenu` follow the theme live via Xresources; rofi, dunst and the SDDM
  theme are generated from the tokens.

## Your apps & the web
- **Default repositories** `nirupresence`, `nirunote`, `nplay` are cloned to
  `~/Git/` on install and updated by `--update-dots`.
- **Quick launch** — `Super+Shift+n` (nirunote), `Super+Shift+o` (nplay),
  plus control-center entries for all three (`nirupi-app.sh NAME`; if a checkout
  is only cloned, it offers to run its installer).
- **Web apps** open in **Helium** (Chromium app mode); `nirupi webapp add|list|remove`.
- **Helium** is provisioned automatically (Debian apt repo, Arch AUR helper, else
  the official tarball) with firefox/brave/chromium fallback.

## Session, idle & power
- Idle ladder (dim → lock → DPMS → suspend) via `~/.config/nirupi/session.conf`
  when the NIRUPI session is used.
- Suspend is undoable (see Lock screen above).
- **Control center** `Super+Shift+m`: lock, suspend, log out, reboot, shut down,
  caffeine, focus, record, window switcher, gaps, keyboard, touchpad, night light,
  theme + wallpaper, day/night, Tailscale, Wi-Fi, Bluetooth, weather, mute, the
  three apps, agent, backup and updates.

## Operations
- `nirupi doctor [--fix]`, `nirupi gc`, `nirupi backup [--schedule]`,
  `nirupi rollback`, `nirupi update`.
- CI (smoke on Debian + Arch, shellcheck), generated `KEYBINDINGS.md`.

## Customising
- Keybindings/colours: `vendor/suckless/dwm/config.h` → rebuild with
  `nirupi migrate dwm --rebuild`.
- Idle/suspend: `~/.config/nirupi/session.conf`
  (`IDLE_*`, `LOCK_ON_SUSPEND`, `SUSPEND_DELAY_SECONDS`).
- Status bar: `~/.config/nirupi/status.conf` (`SHOW_*`).
- Caffeine/recording state lives in `~/.cache/nirupi/`.
