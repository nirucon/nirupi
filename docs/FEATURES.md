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
- `Super+x` (and the power menu) shows a **pure-black** screensaver: the clock is
  always normal digits, and only the **hostname** alternates between **Elder
  Futhark runes** and uppercase ASCII every 30 seconds. **Never automatic.**
- The first key press or click switches to the **blurred desktop lock** (clock +
  ISO date + hostname + AFK), then you type your password. Bundles
  `Noto Sans Runic` (OFL) so the runes always render; falls back to ASCII without
  the font. Tune in `vendor/suckless/slock/config.h`.

## Status-bar pop-ups
- **Click the date** → a centred floating **calendar** TUI (Swedish,
  Monday–Sunday, ISO week numbers; ←/→ months, ↑/↓ years, `t` today, `q` quit).
- **Click the updates count** → the distro's **system update** runs in a centred
  floating terminal (`apt-get` / `xbps-install` / `pacman`).
- Both also live in the control center (`Super+Shift+m`). The bar **agent icon**
  matches the AI workspace tag glyph.

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
- **One palette drives everything.** Switching a theme restyles terminals
  (kitty, alacritty, st), fish, TUI tools (tmux, lazygit, micro, aerc, cmus),
  GTK/Qt, rofi, dunst, the SDDM theme and the status-bar accents — live, no
  rebuild. Dunst colours live in a `dunstrc.d` drop-in, so your own
  notification settings are preserved.

## Clean installs
- Installs what a vanilla system misses: X input driver, `mesa`, `alsa-ucm-conf`,
  the PipeWire↔ALSA bridge, `man-db`, `bash-completion`, XDG desktop portals and
  Noto fonts.
- Auto-detects CPU/GPU vendor and adds matching microcode + VA-API/Vulkan
  (best-effort; NVIDIA prints a hint).
- Enables `tailscaled` and `bluetooth` (and NetworkManager when no competing
  manager is active) so the desktop survives a reboot.
- Arch: refreshes `archlinux-keyring` first, and (opt-in) installs `paru-bin`
  from the AUR so AUR-only apps use the package manager.
- **Theme picker** `Super+Ctrl+t` (`nirupi theme menu`): rofi with colour
  swatches per theme.
- Shipped themes: `noir` (default), `Satie` (monochrome graphite, one muted-gold
  accent), `carl-larsson` (warm umber/watercolour), `hackerman` (phosphor green)
  and `nord-dark`, plus `warm`/`cool`. The picker shows the active theme and a
  one-line description of each.
- Commands: `nirupi theme list`, `nirupi theme preview NAME`,
  `nirupi theme set NAME`.
- **Manual only:** the theme is always chosen by hand (picker or `nirupi theme
  set`); nothing switches automatically on a schedule.
- **Wallpaper-driven palette:** `nirupi theme wallpaper IMAGE`.
- Add your own: drop `MyTheme.env` (same schema) in `vendor/noir/theme/`.
- **Noir day** is a light palette for daylight.

## Capture, clipboard & AI
- **Capture** `Super+Ctrl+Print`: region / window / full screen, saved to
  `~/Pictures/Screenshots` and copied. Optional annotation via `satty` and
  **OCR to clipboard** via `tesseract` (only offered when installed).
- **Clipboard transforms** from the keybinding palette (`Super+Shift+h`):
  case, line sort/unique/reverse, Base64, URL encode/decode, JSON pretty,
  strip ANSI, counts. Uses `xclip`/`wl-clipboard`; JSON/URL need `python3`.
- **Emoji picker** from the palette (bundled list, or `rofimoji` if installed).
- **Ask the agent** `Super+Ctrl+a`: sends the current selection to `opencode`
  with a prompt menu (explain/summarise/translate/fix/…).
- **Ask about a screen region** `Super+Ctrl+s`: capture a region, OCR it
  (tesseract) and send the text to the agent.
- **AI command** `Super+Ctrl+c`: describe a task, the agent proposes a shell
  command, it opens **prefilled and editable** in a terminal and runs only on
  Enter. Nothing is executed automatically.
- **SSH/host picker** `Super+s`: hosts from `~/.ssh/config` and Tailscale.
- **`nirupi reload`** rebuilds dwm only when its sources changed and restarts it
  in place; **`nirupi edit [TOPIC]`** opens a config in `$EDITOR`.
- **Audio output** picker in the control center (`wpctl`/PipeWire).
- **`nirupi help COMMAND`** and a man page; **fish + bash completions**.

## Wallpapers
- **Per workspace (tag):** dwm calls `nirupi-tag-wallpaper.sh` on every tag
  switch; `~/.config/nirupi/wallpapers.conf` maps tags to images (or a random
  pool), and the switch is instant. Toggle in the control center. Works with
  one or several outputs.

## dwm polish
- **smartgaps / smartborders** (no gaps or border on a lone window),
  **in-place restart** `Super+Ctrl+Shift+r` (releases the WM role before
  re-exec), **drag the master factor** (`Super+Button2`), and float rules for
  dialogs/tools (PiP, pavucontrol, Steam, Lutris).

## Launcher, autostart, laptop
- **Unified launcher** `Super+Shift+p` (and `nirupi launch`): one rofi that
  combines installed apps (incl. web apps), **open windows**, the **clipboard
  history** and running a command.
- **Autostart** `~/.config/nirupi/autostart/*.sh`, run at login after dwm is up,
  with `tag: 1-9` to open an app on a workspace and `settle:` for slow starters.
- **Battery guard** for laptops (warn/critical/optional suspend).
- **Notification history** (`nirupi notifications`) and **clipboard cleared on
  lock**.
- **picom is generated from the palette** (tinted shadow, fading); no rounded
  corners.
- **`nirupi doctor --json`** for a machine-readable readiness check.
- **Arrow keys** focus/move windows (`Super+Left/Up` = previous,
  `Super+Right/Down` = next; add `Shift` to move the window in the stack).
- **File search** in the launcher (`files` mode) — find and open any file from
  `Super+Shift+p`.
- **USB mount/unmount** (`nirupi usb`) and **laptop lid control** (`nirupi lid`)
  in the control center.
- **CI smokes Void** as well as Arch and Debian.
- **Status-bar media icons** open the matching folder (Music, Pictures/Photos,
  Videos) when clicked.
- **Bar modes** (`Super+Ctrl+Shift+b`): padded → full-bleed → hidden.
- **Calendar** month view with optional Google iCal sync (`nirupi calendar`).
- **Daily update check** with a notification when packages or repos are behind.

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
  theme, wallpaper, audio output, capture, emoji, clipboard, Tailscale, Wi-Fi,
  Bluetooth, weather, the three apps, agent, backup and updates.

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
