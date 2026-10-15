# Changelog

All notable changes to NIRUPI. Versions are the `VERSION` file value.

## 0.21.5
- Weather panel: parse the hourly fields tab-separated so multi-word conditions
  no longer shift the columns (temperature showed a stray "3°C").

## 0.21.4
- Weather panel: complete WMO code mapping (drizzle, light rain, heavy
  showers, snow grains, …) so codes like 51/53/61 show a description instead of
  "code 51".

## 0.21.3
- Pop-ups open at a comfortable, fixed size (~520x440) centred on the monitor
  instead of filling it. Schema v15.

## 0.21.2
- Fix the empty panel windows: the spec is now passed via `--spec FILE` so the
  panel keeps a real TTY on stdin (curses aborts with "cbreak() returned ERR"
  when stdin is a pipe, which is why battery/weather drew nothing).

## 0.21.1
- **In-place restart now loads the installed build**: dwm re-execs
  `~/.local/bin/dwm` (falling back to `argv[0]`) instead of the running image, so
  `Super+Ctrl+Shift+r` picks up a freshly rebuilt dwm.
- `nirupi reload` borrows `DISPLAY`/`XAUTHORITY` from the running dwm, so it can
  restart dwm even from an SSH/tmux shell that has no display.

## 0.21.0
- **dwm centres and sizes the NIRUPI pop-ups** (info panel, calendar, btop) on
  the monitor: a `centerfloat()` applied when those clients are managed, so the
  panels are always centred regardless of terminal behaviour. Schema v14.

## 0.20.2
- Pop-up windows are sized with kitty's `--cols/--rows` (kitty 0.48 silently
  ignores `initial_window_width/height` overrides, which left the window huge and
  off-centre) and centred once dwm has placed the float.

## 0.20.1
- Panel spec is now rendered **in the order given** (notes can sit between rows,
  e.g. weather's per-day sections), and the width is computed from the widest
  row, so nothing is clipped.

## 0.20.0
- **Unified, framed TUI panels** for the status-bar pop-ups, via a new
  `nirupi-panel.py` (curses): double border with the title in the top edge, a
  palette-coloured layout, label/value rows, optional **usage bars**, dim notes,
  warning colours, correct centring and a size that always fits.
- **Battery** (charge bar, health, status, power, voltage, time remaining),
  **Disk** (per-mount bars) and **Weather** (current + hours + days) now all use
  the panel; the **updates** picker stays a rofi menu (it runs the updater).
- Removed a dead `nirupi-popup-tui.sh` stub.

## 0.19.0
- **Unsticky**: `Super+Ctrl+Alt+s` un-stickies the focused window,
  `Super+Ctrl+Alt+Shift+s` clears every sticky window on the monitor; also in the
  control center (*Unsticky all windows*).
- **Calendar colours**: the view now uses the active palette (title/date/events)
  and opens Google Calendar to the *week* for the selected day, with a clearer
  confirmation message.
- DWM config schema bumped to **v13**.

## 0.18.0
- **Gaps can be restored again**: `Super+g` now always returns to a known gap
  size (15) instead of "whatever it was", which could be 0 after a restart with
  gaps off (only a full dwm restart recovered it before).
- **Sticky windows are visible**: `Super+Ctrl+Shift+s` marks the window with a
  `[S]` in the title, so it is never a mystery which window is on all tags.
- **Screenshots are robust**: the full-screen/Flameshot bindings no longer abort
  when `xclip` is missing or the copy fails — the file is saved and you are told.
- **Status bar**: the kernel/hostname segments are no longer stale for up to an
  hour after a kernel/hostname change (the cache is tied to the value).
- **Caffeine recovery**: a leftover caffeine flag from a crashed session is
  cleared (and DPMS restored) at the next login.
- **Control center**: the gaps entry notes `Super+g` and toggling confirms how
  to undo it.
- **`doctor`** also checks the optional tools (xclip, maim, flameshot,
  gammastep, brightnessctl, ffmpeg, rofi) and hints which are missing.
- DWM config schema bumped to **v12**.

## 0.17.6
- **Removed the next-event segment** from the status bar (the stray
  `Sat 17:00 …` between host and date).
- **Battery and weather pop-ups are now centred TUI panels** (a clean floating
  kitty window) instead of a rofi list; updates via the control center still use
  the menu picker.
- **Nextcloud** segment gets a little more space after the cloud glyph.
- **Calendar** visual refresh: title rule, bold weekday header, alternating week
  shading, clearer day/selection/today markers, a divider and bulleted events,
  plus a larger default window (68×26).
- DWM config schema bumped to **v11** (float rule for the info pop-up).

## 0.17.5
- **Touchpad toggle** (`Super+Shift+t`): look the device up by its id instead of
  its name. A disabled device is listed with a leading marker (e.g. `∼ `), so
  re-enabling by name failed and the touchpad stayed off.
- **btop pop-up**: force a size that satisfies btop's minimum via the window
  manager, then centre (the kitty size alone was unreliable).

## 0.17.4
- **btop pop-up**: set `remember_window_size=no` so kitty stops restoring the
  old (too small) size — it now opens large enough for btop's 80×24 minimum and
  centred.
- **Calendar**: `remember_window_size=no` and a larger default window (72×24) so
  the footer fits; shorter footer.
- **Next calendar event** in the bar is prefixed with `»` so it reads as an
  event rather than random text.

## 0.17.3
- The **btop pop-up** (temperature/CPU click) now requests a comfortable size
  (110×34, ≥ btop's 80×24 minimum) and centres its floating window.

## 0.17.2
- **Calendar**: the iCal URL prompt now accepts arbitrary-length input (it used
  to truncate to the window width, so a pasted Google URL was cut and produced no
  events); several iCal URLs can be added (`s` adds, `x` clears) and merged; the
  selected day is a clear highlighted box you move around while *today* stays
  marked; sync status/errors are shown.
- **Weather pop-up** now uses **Open-Meteo** (the same source as the bar),
  defaults to Ljungskile, and lets you change the location by name (geocoded).
- **Battery pop-up** no longer aborts when a driver exposes `charge_full`
  instead of `energy_full` (Void) or omits `power_now`.
- **Status bar**: spacing around segment separators is normalised (fixes the
  uneven gap by the Nextcloud icon).
- **Keybinding viewer**: friendly function names and fuller descriptions
  (including the float move/resize keys).

## 0.17.1
- Apply the hostname-specific monitor layout (`apply-screenlayout.sh`) at
  session start, so a machine with a known multi-monitor setup is configured
  automatically. The `othala` case (top monitor rotated 180°, stacked
  vertically so the pointer moves up/down) now only applies when both outputs
  are connected, otherwise it falls back to `xrandr --auto`. Also available in
  the control center as *Apply screen layout*.

## 0.17.0
- **Richer status-bar pop-ups**: clicking a segment shows information in a
  floating rofi/dmenu instead of opening a browser or terminal —
  **Updates** (list of pending packages; *Update now* runs the updater),
  **Temperature/CPU** (`btop` in a floating terminal), **Battery** (charge,
  status, health, power draw, time remaining), **Disk** (per-mount usage) and
  **Weather** (SMHI forecast; needs `jq`, `WEATHER_LAT`/`WEATHER_LON` override).
- **Next calendar event in the status bar** (`SHOW_NEXTEVENT`), read from the
  Google iCal the calendar is synced to (e.g. "in 25m Standup").
- **`nirupi changes [VERSION]`** shows a version's changelog; `nirupi update`
  now prints the changelog delta.
- **`nirupi fleet`** — read-only status across the hosts in
  `~/.config/nirupi/fleet.conf` (version, session, pending updates; needs SSH
  keys, never sudo).
- `doctor` now checks the **session** (is dwm under nirupi-session?) and the
  **locale** (UTF-8), plus a legacy-session-file hint.
- DWM config schema bumped to **v10** (float rule for the btop pop-up).

## 0.16.0
- **Sticky windows** (`Super+Ctrl+Shift+S`): keep the focused window visible on
  every tag (music, notes, a reference).
- **Keyboard move/resize of floating windows**: `Super+Ctrl+arrows` move,
  `Super+Ctrl+Shift+arrows` resize. No mouse needed for floats/PiP/dialogs.
- **Fibonacci/dwindle layout** (`Super+Ctrl+E`): each split halves the remaining
  area (new `[F]` layout).
- **Calendar pop-up fits its window**: the drawing is now adaptive — every line
  is truncated and the event list only uses the rows that fit, so a small
  floating terminal no longer wraps; `KEY_RESIZE` is handled and the default
  window is a little larger.
- DWM config schema bumped to **v9**.

## 0.15.1
- Installer guard: a leftover plain `dwm.desktop`/`dwm-session` (from before
  NIRUPI) no longer shadows the NIRUPI session — `ensure_nirupi_session`
  repoints the legacy launcher to `nirupi-session` (backup kept), so the
  session-based features (idle, autostart, daily update check, per-tag
  wallpapers) actually run.

## 0.15.0
- **Status-bar media icons open their own folder**: the music/photo/video
  counts are now three separate clickable sections (Music, Pictures/Photos,
  Videos). Two section ids were consolidated (memory+uptime, date+time) to free
  ids without touching the forbidden whitespace id range (9–13).
- **Bar modes**: `Super+Ctrl+Shift+b` cycles padded bar → full-bleed bar →
  hidden (also in the control center as *Bar mode*). `Super+Ctrl+b` still
  toggles show/hide.
- **Calendar rewrite**: English UI, Monday-first (Mon..Sun), ISO week numbers,
  a cleaner layout with today highlighted and adjacent-month days dimmed.
  Optional **Google Calendar sync** via a secret iCal URL set from inside the
  TUI (`s`); the selected day's events are listed and `o` opens that day in
  Google Calendar. `nirupi calendar`.
- **Daily update check**: once a day (in the session, so it works on Arch,
  Debian and Void), it notifies "Updates available" with the package and repo
  counts and how to run the update. `nirupi-updatecheck.sh`; respects
  `NIRUPI_NO_NOTIFY=1`.
- **Terminal/status alignment**: the terminal text inset now matches the bar
  (kitty `window_padding_width` 8); the full-bleed bar mode removes the side
  padding entirely.
- DWM config schema bumped to **v8**.

## 0.14.6
- Fix status-bar icons showing as literal `\uXXXX` text (e.g. the weather,
  mic, DND, recording, Bluetooth, caffeine and AI glyphs) on systems with no
  UTF-8 locale: the glyphs are now written as real UTF-8 in `dwm-status.sh`
  instead of `\u`/`\U` printf escapes (which bash only expands in a UTF-8
  locale). The script also picks a UTF-8 locale when the session has none.

## 0.14.5
- `nirupi gc` now prunes release snapshots that reference version directories
  which no longer exist (they cannot roll back), so their old version
  directories are cleaned up too.

## 0.14.4
- New `nirupi migrate binaries --rebuild`: rebuilds **dwm, dmenu and st** into
  the current version directory and relinks them. Upgrades done with
  `--update-dots` only rebuilt dwm, so dmenu/st could linger on ancient version
  directories; this brings them onto the current version and lets `nirupi gc`
  prune the old directories.

## 0.14.3
- `nirupi lid` prints the desktop (no-lid) message to stdout so it is visible in
  a terminal, not just as a notification.

## 0.14.2
- `nirupi lid` detects machines without a lid switch (stationary desktops) and
  says so instead of offering lid settings.

## 0.14.1
- `nirupi lid` now handles **elogind** as well as systemd-logind (Void uses
  elogind), writing to the correct drop-in directory and restarting the right
  service.

## 0.14.0
- **Arrow keys**: `Super+Left/Up` focus the previous window, `Super+Right/Down`
  the next; with `Shift` they move the focused window within the stack.
- **File search in the unified launcher** (`Super+Shift+p`): a `files` mode that
  searches your home with fd/find and opens the selection.
- **USB mount/unmount** from the control center (and `nirupi usb`) via udisks2 —
  no daemon of its own.
- **Laptop lid behaviour** (`nirupi lid`, control center): sets logind's
  `HandleLidSwitch` (lock/suspend/ignore/…) through a drop-in. systemd only.
- **CI also smokes Void** (voidlinux container) alongside Arch and Debian.
- Fix: `docs/KEYBINDINGS.md` no longer labels `Super+Shift+p` "rofi -show run".
- DWM config schema bumped to **v7**.

## 0.13.1
- **Signal Desktop** is installed by default: Arch/CachyOS via `signal-desktop`
  (extra), Debian via Signal's official apt repository (`ensure_signal`). Void
  has no package, so it is skipped there.

## 0.13.0
- **Unified launcher** on `Super+Shift+p`: one rofi for apps (incl. web apps),
  open windows, clipboard history and running a command.
- **AI rewrite** on `Super+Ctrl+r`: rewrite the current selection in place (the
  result is typed back into the focused field/editor).
- **Autostart** (`~/.config/nirupi/autostart/*.sh`), run at login after dwm is
  up. Per-entry directives: `tag: 1-9` opens the app on that workspace,
  `settle:` waits for slow starters and `enabled: false` skips a file.
  Documented for desktop apps and TUI apps (wrap in a terminal).
- **Low-battery guard** (laptops): warn at `BATTERY_WARN`, critical at
  `BATTERY_CRIT`, optional `BATTERY_SUSPEND` (all in session.conf).
- **Notification history** (`nirupi notifications`, control center) and the
  **clipboard is cleared on lock** (`LOCK_CLEAR_CLIPBOARD`, default on).
- **Themed picom** generated from the palette (tinted shadow + fading); no
  rounded corners.
- **`nirupi doctor --json`**; `nirupi update` now refreshes scripts/theme and
  rebuilds+restarts dwm if needed (packages still need `--apply`).
- Clean installs enable **`fstrim.timer`** (SSD) and **`paccache.timer`**.
- Fixes: the status-bar host segment works without the `hostname` binary (and
  the host click falls back to `ip`); the dwm-status cache is cleared when the
  bar restarts after an upgrade; `doctor` hints about Debian non-free-firmware;
  `theme set noir` no longer writes a redundant override.
- DWM config schema bumped to **v6**.

## 0.12.2
- Void: enable the nonfree repository (`void-repo-nonfree`) and use the correct
  vendor package names (`mesa-vulkan-intel`/`mesa-vulkan-radeon`,
  `intel-media-driver`/`mesa-vaapi`) so microcode and VA-API/Vulkan drivers
  resolve on a clean install.

## 0.12.1
- AUR bootstrap is now robust: prefer `paru-bin`, but **verify it actually
  runs** and fall back to `yay-bin` when the prebuilt paru is incompatible
  (e.g. a `libalpm` soname mismatch after a pacman upgrade). Build+install from
  the AUR snapshot with `makepkg` + `pacman -U` instead of `makepkg -si` (which
  needs a terminal).

## 0.12.0
- **Clean-install completeness (Arch/Debian/Void):** the package list now
  includes what a vanilla install otherwise misses — X input driver
  (`xf86-input-libinput` / `xserver-xorg-input-libinput`), `mesa` (OpenGL),
  `alsa-ucm-conf`, the PipeWire↔ALSA bridge (`pipewire-alsa` / `alsa-pipewire`),
  `man-db`, `bash-completion`, XDG desktop portals and general Noto fonts.
- **Vendor auto-detection:** CPU/GPU vendor is detected and matching microcode
  and VA-API/Vulkan packages are installed best-effort (Intel/AMD; NVIDIA gets a
  hint). Mesa is always installed.
- **Arch AUR helper (opt-in):** if no `yay`/`paru` exists, `--apply` offers to
  install `paru-bin` from the AUR, so AUR-only apps (the Helium browser) install
  via the package manager instead of an upstream tarball.
- **Services enabled on a clean install:** `tailscaled` and `bluetooth` (and
  NetworkManager when no competing manager is active) are enabled so the
  desktop's network/lock features survive a reboot.
- **Arch:** refresh `archlinux-keyring` before the full upgrade.
- `nirupi doctor` hints about a missing AUR helper, `man-db`, bash-completion,
  unenabled Tailscale and missing audio sinks.

## 0.11.1
- Fix `nirupi edit` topic resolution (a stray `:` in the resolved path) and add
  `nirupi edit --path TOPIC` to print the file path.

## 0.11.0
- **`nirupi reload`** — rebuild dwm only when its sources changed, then restart
  it in place (safe: a failed build keeps the running dwm). Also in the control
  center as *Reload desktop…*.
- **`nirupi edit [TOPIC]`** — open a NIRUPI config (`status`, `session`, `apps`,
  `agents`, `browser`, `wallpapers`, `theme`, `dwm`) in `$EDITOR`.
- **SSH/host picker** on `Super+s` (from `~/.ssh/config` and Tailscale peers).
- **Ask the agent about a screen region** on `Super+Ctrl+s`: region → OCR
  (tesseract) → agent.
- **AI command** on `Super+Ctrl+c`: describe a task, the agent suggests a shell
  command shown **prefilled and editable** in a terminal; it runs only when you
  press Enter. Nothing executes automatically.
- Config schema bumped to **v5** (three new bindings). Palette and control
  center entries for all of the above; docs, completions and man page updated.

## 0.10.4
- **Removed the wallpaper crossfade entirely.** Per-workspace wallpaper
  switching is instant (`feh`/`xwallpaper`/`hsetroot`): no ImageMagick, no
  stutter, fewer moving parts.

## 0.10.3
- Per-workspace wallpaper switching is now **instant by default**: the
  ImageMagick crossfade was heavy and stuttered on X11. The crossfade is still
  available as an opt-in (`FADE=1` in `~/.config/nirupi/wallpapers.conf`, or
  `--fade`), reworked to build the frames up-front and play them evenly.

## 0.10.2
- The theme-switch notification is now suppressed when `NIRUPI_NO_NOTIFY=1` is
  set, and the test suite sets it — so running the tests (which switch through
  every theme) can never pop desktop notifications, even in a graphical session.

## 0.10.1
- Themes are **manual only**. Removed the day/night auto switcher
  (`nirupi-theme-auto.sh`) and its control-center entry, so nothing changes the
  theme on a schedule. Pick one with `Super+Ctrl+t`, `nirupi theme set NAME` or
  `nirupi theme menu`.

## 0.10.0
- **dwm polish:** smartgaps + smartborders (no gaps/border on a lone window),
  **in-place restart** on `Super+Ctrl+Shift+r` (releases the WM role before
  re-exec, so no competing window manager), **drag the master factor** with
  `Super+Button2`, and float rules for dialogs/tools (PiP, pavucontrol, Steam,
  Lutris). Config schema bumped to **v4**.
- **Light theme `Noir day`** (warm paper, dark readable accents) for daylight.
- **Capture** (`Super+Ctrl+Print`): region/window/full, optional annotation
  (satty) and **OCR to clipboard** (tesseract).
- **Ask the agent about the selection** (`Super+Ctrl+a`): pick a prompt
  (explain/summarise/translate/fix/…) and send the current selection.
- **Per-workspace wallpapers** with a short ImageMagick crossfade: configure in
  `~/.config/nirupi/wallpapers.conf` (`default=~/Pictures/Wallpapers` random
  pool, optional per-tag images) and toggle from the control center.
- **Emoji picker**, **clipboard transforms** (case/base64/JSON/URL/…) and an
  **audio-output picker**, available from the keybinding palette and the
  control center.
- **`nirupi help [command]`** plus a **man page**, and **fish + bash
  completions**.

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
