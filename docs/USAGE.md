# NIRUPI — quick usage manual

A short, practical guide to living with NIRU Noir. For install/upgrade see the
[README](../README.md); for a clean-checkout walkthrough see
[TEST-CHECKLIST.md](TEST-CHECKLIST.md).

## First login

You land in **dwm**. There is no mouse-driven desktop: everything is keyboard
first, plus a small, clickable status bar. If something looks bright/white at
startup, run `nirupi theme apply`.

## Everyday keys

| Key | Action |
|---|---|
| `Super+Enter` | Terminal (kitty) |
| `Super+Shift+Enter` | Alacritty |
| `Super+p` | dmenu launcher |
| `Super+Shift+p` | **Unified launcher** (apps, windows, clipboard, files, run) |
| `Super+Ctrl+r` | Rewrite the selection in place (AI) |
| `Super+Left` / `Super+Up` | Focus the previous window |
| `Super+Right` / `Super+Down` | Focus the next window |
| `Super+Shift+Left` / `Super+Shift+Up` | Move the focused window back |
| `Super+Shift+Right` / `Super+Shift+Down` | Move the focused window forward |
| `Super+Ctrl+b` | Show/hide the bar |
| `Super+Ctrl+Shift+b` | Cycle bar: padded → full-bleed → hidden |
| `Super+Ctrl+Shift+s` | Sticky: keep the window on all tags |
| `Super+Ctrl+e` | Fibonacci / dwindle layout |
| `Super+Ctrl+arrows` | Move the focused floating window |
| `Super+Ctrl+Shift+arrows` | Resize the focused floating window |
| `Super+b` | Browser (resolver) |
| `Super+a` | **Agent** (opencode) |
| `Super+Ctrl+t` | **Theme picker** (Noir/Satie/Carl Larsson/…) |
| `Super+s` | **SSH hosts** (`~/.ssh/config` + Tailscale) |
| `Super+Ctrl+a` | **Ask the agent** about the current selection |
| `Super+Ctrl+s` | **Ask the agent** about a screen region (OCR) |
| `Super+Ctrl+c` | **AI command** (describe → review → run) |
| `Super+Ctrl+Print` | **Capture** menu (region/window/full + annotate + OCR) |
| `Super+Ctrl+Shift+r` | **Restart dwm** in place (after a rebuild) |
| `Super+Shift+h` | **Keybinding palette** (search everything) |
| `Super+Alt+k` | Full keybinding table (interactive TUI) |
| `Super+Shift+m` | **Control center** |
| `Super+Esc` | Lock (`nirupi lock` → slock) |
| `Super+Shift+q` | **Log out** (asks for confirmation) |
| `Super+n` | **Night light** toggle (gammastep/redshift) |
| `Super+Shift+e` | Toggle real fullscreen |
| `Super+Ctrl+,` / `Super+Ctrl+.` | Cycle layouts |
| `Super+Shift+u` | Jump to the urgent window |
| `Super+Shift+w` | Next wallpaper |
| `Super+Shift+r` | Reload theme colours (Xresources) |
| `Super+q` | Close focused window |

The full, searchable list is `Super+Shift+h` (or `nirupi keys`; `Super+/` on US layouts). It clearly marks
**apps** vs **keybindings**: pressing Enter on an app launches it, on a
keybinding it copies the shortcut.

## The status bar

Segments (left to right): agent, media counts, volume, mic-mute, now playing,
network, Nextcloud, battery, temperature, DND, recording, updates, kernel,
host, weather (Ljungskile), date, time.

Clicks on the bar (left = act, right = info where noted):

| Section | Left click | Right click |
|---|---|---|
| Agent icon | opencode agent picker | |
| Media counts | open the Music folder | |
| Volume | mute (scroll = volume) | show level |
| Mic | toggle mic mute | |
| Now playing | play / pause | |
| Network | Wi‑Fi menu | connections + IP |
| Nextcloud | open the client | |
| Battery | details | |
| Temperature | details | |
| Do not disturb | toggle | |
| Recording | open Videos | |
| Updates | check updates | |
| Weather | forecast | |
| Kernel / Host | details / hostname+IP | |
| Date / Time | full date / time | |

`nirupi status --once` prints the bar once as text; `nirupi status --json`
prints it as JSON (handy for scripts/tests).

Tune it in `~/.config/nirupi/status.conf` (this file is yours and is never
overwritten): toggle segments with `SHOW_*`, set weather coordinates, force bar
colour with `BAR_COLOR=1`, or change cache intervals. Restart the session to
re-read it.

## Control center — `Super+Shift+m`

One menu for: lock, suspend, log out, reboot, shut down, choose a theme,
toggle wallpaper mode, next wallpaper, Wi‑Fi, Bluetooth, weather, mute, agent,
backup, check updates.

## Agent (opencode)

`Super+a` or `nirupi agent`. Profiles live in `~/.config/nirupi/agents.conf`
(`name|command`), e.g.:

```
default|opencode
deepseek|opencode --model deepseek/deepseek-chat
codex|opencode --model openai/gpt-5-codex
claude|opencode --model anthropic/claude-sonnet-4
```

API keys/accounts stay in opencode's own config — never in this repo.

## Theme

The whole desktop is generated from **one palette** (`vendor/noir/theme/<name>.env`),
so a theme change restyles terminals, fish, TUI tools, GTK/Qt, rofi, dunst, the
SDDM theme and the status bar — live, without a rebuild.

- **Pick a theme:** `Super+Ctrl+t` (rofi picker with colour swatches), or
  `nirupi theme menu`.
- **List / preview:** `nirupi theme list`, `nirupi theme preview Satie`.
- **Apply by name:** `nirupi theme set NAME` (e.g. `noir`, `Satie`,
  `carl-larsson`, `hackerman`, `nord-dark`, `warm`, `cool`).
- **Follow the wallpaper (opt-in):** `nirupi theme wallpaper /path/image.jpg`
  (ImageMagick) then reloads terminals and the bar. Back to static:
  `nirupi theme mode noir`.
- `Super+Shift+r` re-applies the dwm colours.

Shipped themes:

| Name | Look |
|---|---|
| `noir` | Cold, near-black monochrome (default) |
| `Satie` | Flat monochrome graphite, one muted-gold accent |
| `carl-larsson` | Warm umber, cream and earth/watercolour accents |
| `hackerman` | Phosphor green on black — CRT hacker terminal |
| `nord-dark` | Polar Night blues with Nord frost/aurora accents |
| `noir-day` | Light warm paper — readable in daylight |
| `warm` / `cool` | Noir with a warm or cool cast |

`st`/`dmenu`/dwm read the palette from Xresources at startup (and on `SIGUSR1`);
**kitty, alacritty, fish, tmux, lazygit, micro, aerc, cmus, rofi and SDDM are
generated from the active palette** on every `nirupi theme apply`. **Dunst**
colours are written to `~/.config/dunst/dunstrc.d/90-nirupi.conf`, a drop-in
that outranks your base `dunstrc` — so your own notification settings stay
yours and still follow the theme.

Add your own theme: copy `vendor/noir/theme/Satie.env` to
`vendor/noir/theme/MyTheme.env`, edit the hex values, and
`nirupi theme set MyTheme`.

The **status bar** follows the theme automatically (each segment is drawn from
the palette accents). To force colour in a monochrome mode set `BAR_COLOR=1` in
`~/.config/nirupi/status.conf`.

## Screen lock, idle & effects

The idle ladder in `~/.config/nirupi/session.conf` runs (each step optional):

```
dim  ->  lock  ->  DPMS off  ->  suspend
```

```sh
IDLE_DIM_MINUTES=5        # dim (brightnessctl) or blank; 0 = off
IDLE_LOCK_MINUTES=10      # slock; 0 = off
IDLE_DPMS_MINUTES=20      # display off; 0 = off
IDLE_SUSPEND_MINUTES=0    # suspend; 0 = off (opt in)
IDLE_WARN_SECONDS=30
LOCK_ON_SUSPEND=1         # lock before the machine sleeps (xss-lock/logind)
```

The full ladder needs `xidlehook`; `xautolock` and `xss-lock` lock only.
`Super+Shift+q` asks before logging out, and `Super+n` toggles the night light.

## Web apps

Web apps open in **Helium** (Chromium `--app` mode), falling back to
brave/chromium. Manage them so they appear in dmenu/rofi/palette:

```sh
nirupi webapp add "Work Mail" https://mail.example.com/
nirupi webapp add "Teams" https://teams.microsoft.com/ --separate
nirupi webapp list
nirupi webapp remove "Work Mail"
```

## Capture, clipboard & AI

- **Capture** (`Super+Ctrl+Print`, or the control center): region, window or
  full screen. Saved to `~/Pictures/Screenshots` and copied to the clipboard.
  With `satty` installed you also get annotation; with `tesseract`,
  *OCR from region* copies the recognised text.
- **Clipboard transforms** (keybinding palette `Super+Shift+h` → *Transform*):
  UPPERCASE/lowercase/Title, sort/unique/reverse lines, Base64 and URL
  encode/decode, JSON pretty, strip ANSI, count lines/words/chars.
- **Emoji** (palette → *Emoji*): pick one, copied to the clipboard.
- **Ask the agent** (`Super+Ctrl+a`): select text anywhere, choose a prompt
  (explain / summarise / translate to EN or SV / fix / explain error /
  refactor), and the answer opens in a terminal via `opencode run`.
- **Ask about a screen region** (`Super+Ctrl+s`): select a region, it is OCR'd
  (tesseract) and sent to the agent — handy for errors you cannot select.
- **AI command** (`Super+Ctrl+c`): describe what you want in plain language,
  the agent suggests a shell command, and it opens in a terminal **prefilled and
  editable** — nothing runs until you press Enter.

## Fleet & maintenance

- **SSH hosts** (`Super+s`): pick a host from `~/.ssh/config` and Tailscale
  peers; opens a shell in a terminal.
- **`nirupi reload`**: rebuild dwm **only if its sources changed**, then restart
  it in place (safe: a failed build keeps the running dwm). Same as the control
  center → *Reload desktop…*.
- **`nirupi edit [TOPIC]`**: open a NIRUPI config (`status`, `session`, `apps`,
  `agents`, `browser`, `wallpapers`, `theme`, `dwm`) in `$EDITOR`.

## Wallpapers

- **Set / rotate:** `nirupi wallpaper set FILE`, `nirupi wallpaper next`, or
  `Super+Shift+w`.
- **Per workspace (tag):** dwm swaps the wallpaper **instantly** on tag switch.
  Edit `~/.config/nirupi/wallpapers.conf` (`PER_TAG=1`,
  `DEFAULT_DIR` = random pool, optional `N=/path` per tag) and toggle it from
  the control center (*Wallpapers per workspace: toggle*).
- **Theme from wallpaper:** `nirupi theme wallpaper IMAGE`.

## Launcher — `Super+Shift+p`

One rofi for everything: **type to run a command**, or pick an installed app
(including your web apps), an open window (*window* mode), a clipboard entry
(*clip* mode) or **a file** (*files* mode, searched with fd/find and opened with
xdg-open). Switch modes with `Ctrl+Tab`. `nirupi launch` opens the same.

## Autostart — `~/.config/nirupi/autostart/*.sh`

Files here run once at login, after dwm is up. Each file is a small shell script
whose leading comments carry directives:

```sh
# name: Agent            # label shown by `nirupi autostart list`
# tag: 2                 # open on workspace 2 (1-9); omit for the current one
# settle: 3              # seconds to wait after launching on that tag
# enabled: false         # skip without deleting the file
exec kitty -e opencode   # desktop app: the command line goes here
```

- **Desktop app:** the command directly, e.g. `exec helium-browser`.
- **TUI app:** wrap it in a terminal so it gets a window, e.g.
  `exec kitty -e btop` (or `st -e cmus`).
- Files run in lexical order — prefix `10-`, `20-` to control the order.
- `nirupi autostart list` shows what is configured; `nirupi autostart run` runs
  it now (handy for testing). Placement briefly switches to the tag, launches
  the app, waits `settle` seconds, then returns to workspace 1 — increase
  `settle` for slow starters.

## Notifications & battery

- **History:** `nirupi notifications` (control center → *Notifications:
  history…*) lists recent notifications; picking one re-pops it.
- **Clipboard on lock:** cleared when the screen locks (set
  `LOCK_CLEAR_CLIPBOARD=0` in `session.conf` to keep it).
- **Battery (laptops):** warn at `BATTERY_WARN` %, critical at `BATTERY_CRIT` %,
  optional suspend with `BATTERY_SUSPEND=1` — all in `~/.config/nirupi/session.conf`.

## Disks & lid

- **USB drives:** control center → *USB: mount/unmount…* (or `nirupi usb`) lists
  removable partitions and mounts/unmounts the one you pick via udisks2.
- **Laptop lid:** `nirupi lid` shows the current behaviour and, from a terminal,
  sets `HandleLidSwitch` (lock, suspend, ignore, …) in a logind drop-in. systemd
  systems only; the control center entry opens it in a terminal.

## Calendar — click the clock, or `nirupi calendar`

A month view (English UI, **Monday-first**, ISO week numbers, today
highlighted). Keys: arrows move the day, `PgUp`/`PgDn` change month, `</>`
change year, `t` today, `q` quit.

- **Google Calendar (optional, read-only):** press `s` and paste your calendar's
  **secret iCal URL** (Google Calendar → Settings → *Secret address in iCal
  format*). That day's events are then listed under the grid; `o` opens the
  selected day in Google Calendar for editing. The URL lives in
  `~/.config/nirupi/calendar.conf`. For two-way sync, `gcalcli` or
  `vdirsyncer` + `khal` are documented opt-ins.

## Bar modes

`Super+Ctrl+Shift+b` (or control center → *Bar mode*) cycles **padded** (default,
floating bar) → **full-bleed** (bar and windows flush to the screen edges) →
**hidden** (focus mode). `Super+Ctrl+b` still just shows/hides the bar; windows
and dmenu follow the mode automatically.

## Floating windows & layouts

- **Move/resize without the mouse:** focus a floating window and use
  `Super+Ctrl+arrows` to nudge it, `Super+Ctrl+Shift+arrows` to resize it
  (tiled windows are untouched).
- **Sticky** (`Super+Ctrl+Shift+s`): the focused window stays visible on every
  tag — handy for music, notes or a reference.
- **Fibonacci/dwindle** (`Super+Ctrl+e`, layout `[F]`): each split halves the
  remaining area.

## Updates at a glance

Once a day (while the session runs) nirupi checks for updates and pops a
notification: system packages and any `~/Git` repos that are behind. Apply with
`nirupi update` (nirupi + repos) and `sudo nirupi updates` (packages). Silence
notifications with `NIRUPI_NO_NOTIFY=1`.

## Status-bar pop-ups

Click a status segment for information in a floating panel: **Updates** lists
pending packages (*Update now* runs the updater), **Temperature/CPU** opens
`btop`, **Battery** shows health/power/remaining, **Disk** shows per-mount
usage, and **Weather** shows the SMHI forecast (`jq`; set `WEATHER_LAT`/
shows the upcoming Google Calendar event from the synced iCal.

## Fleet & changes

- **`nirupi changes [VERSION]`** — the changelog for a version; `nirupi update`
  prints the delta automatically.
- **`nirupi fleet`** — read-only status across the hosts in
  `~/.config/nirupi/fleet.conf` (one per line): version, session and pending
  updates. Needs SSH keys; never uses sudo.

## Customize

| File | Purpose |
|---|---|
| `~/.config/nirupi/apps.conf` | Extra packages per distro + Git repos |
| `~/.config/nirupi/session.conf` | Idle lock, start dunst/picom |
| `~/.config/nirupi/status.conf` | Status bar segments, weather, cache |
| `~/.config/nirupi/agents.conf` | opencode profiles |
| `~/.config/nirupi/browser.conf` | Default browser (`nirupi browser set X`) |
| `~/.config/nirupi/tokens.env` | Active palette (from `nirupi theme set`) |
| `~/.config/nirupi/theme/` | Generated colour fragments (do not edit) |
| `~/.config/dunst/dunstrc.d/90-nirupi.conf` | Generated dunst colours (do not edit) |
| `~/.config/nirupi/wallpapers.conf` | Per-workspace wallpapers (`nirupi wallpaper per-tag …`) |
| `~/.config/nirupi/autostart/` | Login autostart entries (`*.sh`, per-workspace) |

DWM keybindings/colors are compiled in `vendor/suckless/dwm/config.h`; rebuild
after editing with `nirupi migrate dwm --rebuild`.

## Update & rollback

```sh
nirupi update                 # git pull + next steps
# or manually:
cd ~/Git/nirupi
git pull --ff-only
bash ./install.sh --diff      # what will change
bash ./install.sh --plan
# then from a local TTY:
bash ./install.sh --apply
```

Shortcuts: `bash ./install.sh --update-dots` refreshes scripts + theme only
(no packages, no dwm rebuild). `bash ./install.sh --adopt-dots` force-adopts
the bundled dotfiles and DWM config (previous files are backed up).

## Maintenance

```sh
nirupi gc --dry-run           # show old versions/snapshots/backups to prune
nirupi gc --yes               # prune (keeps current + N newest)
nirupi gc --yes --legacy      # also prune old legacy archives
nirupi status --once|--json   # bar for scripts
nirupi backup                 # back up user config now
nirupi backup --schedule      # weekly backup (systemd user timer or cron)
nirupi backup --unschedule    # disable the scheduled backup
```

Rollback (local TTY only; touches only `$HOME` and `~/.local/state/nirupi/`):

```sh
nirupi rollback --all                 # latest config backup + binary links
nirupi rollback --configs <RUN_ID>    # one config backup
nirupi rollback --binaries            # binary links only
```

## Troubleshooting

```sh
nirupi doctor            # fonts, tools, agent, theme
nirupi doctor --fix      # best-effort: Nerd Font + idle-lock tool
bash ./install.sh --verify
```

- Missing status icons? Install the Nerd Font (answered during install) or
  re-run `./install.sh --theme-only`. `nirupi doctor --fix` can fetch it.
- A segment doesn't click? Confirm dwm was rebuilt with the patches:
  `bash tests/dwm-patches.sh` in the source tree.
- Upgrading kept your old config on purpose. New versions are offered as
  `*.nirupi-new` next to the original — merge manually when ready.
- **The bar looks unchanged after an upgrade?** Your old scripts were kept.
  Adopt the new ones (backups are kept) with `./install.sh --update-dots`, then
  log out and back in. `./install.sh --apply --refresh` does the same as part of
  a full upgrade.
- `~/.local/state/nirupi/installed.env` records version and schema;
  `~/.local/state/nirupi/legacy/` holds archived old binaries.

## Where things live

- Binaries/links: `~/.local/bin`, versioned builds under `~/.local/lib/nirupi/`.
- User config: `~/.config/<app>/` and `~/.config/nirupi/`.
- State/backups/legacy: `~/.local/state/nirupi/`.
- DWM config: `~/.config/suckless/dwm/config.h`.

## Features added in 0.7 (NIRU Noir)

Full detail in [`FEATURES.md`](FEATURES.md). Quick keys:

| Key | Action |
|---|---|
| `Super+w` | Window switcher (rofi) |
| `Super+r` | Toggle screen recording |
| `Super+g` | Toggle gaps |
| `Super+Shift+e` | Real fullscreen |
| `Super+Shift+c` | Caffeine (stay awake) |
| `Super+Shift+d` | Focus / do-not-disturb |
| `Super+Shift+l` | Keyboard layout se/us |
| `Super+Shift+t` | Touchpad toggle |
| `Super+Shift+n` | nirunote |
| `Super+Shift+o` | nplay |
| `Super+Shift+r` | Reload theme colours |
| `Super+x` | Screensaver (runes, locks on input) |
| `Super+Shift+q` | Power menu (suspend/logout/reboot/shutdown + timers) |

Clicking the **date** in the status bar opens a centred floating **calendar**
(Swedish, Mon–Sun, ISO week numbers); clicking the **updates** count runs the
distro's **system update** in a centred floating terminal. The **lock screen**
(`Super+Esc`) shows a minimal clock, ISO date, hostname and AFK timer.
**Suspend** (`Super+Shift+Esc`) locks, waits `SUSPEND_DELAY_SECONDS` (default 3s)
and suspends — unlock within the wait to cancel. **Clipboard history is now
automatic** (`Super+v`). The **control center** (`Super+Shift+m`) collects all of
the above. No function keys are used; see `Super+Alt+k` for the full, up-to-date
list (including every tag binding).
