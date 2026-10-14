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
| `Super+Shift+p` | rofi run |
| `Super+b` | Browser (resolver) |
| `Super+a` | **Agent** (opencode) |
| `Super+Shift+h` | **Keybinding palette** (search everything) |
| `Super+Shift+m` | **Control center** |
| `Super+Esc` | Lock (slock) |
| `Super+Shift+w` | Next wallpaper |
| `Super+F5` | Reload theme colors (Xresources) |
| `Super+q` | Close focused window |
| `Super+Shift+q` | Quit dwm (end session) |

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

One menu for: lock, suspend, log out, reboot, shut down, apply Noir theme,
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

- Static Noir (default): `nirupi theme apply` or `./install.sh --theme-only`.
- Follow the wallpaper (opt-in): `nirupi theme wallpaper /path/to/image.jpg`
  (uses ImageMagick, then reloads terminals and the bar). `Super+F5` re-applies
  the dwm colors. Back to static: `nirupi theme mode noir`.

Noir is monochrome: the status bar uses no colour codes in noir mode. Colour is
applied automatically only in wallpaper mode (or force it with `BAR_COLOR=1` in
`~/.config/nirupi/status.conf`).

## Screen lock & idle

The screen locks with `slock` after **10 minutes** of inactivity. Change or
disable it in `~/.config/nirupi/session.conf`:

```sh
IDLE_LOCK_MINUTES=10   # 0 disables
IDLE_WARN_SECONDS=30
```

## Customize

| File | Purpose |
|---|---|
| `~/.config/nirupi/apps.conf` | Extra packages per distro + Git repos |
| `~/.config/nirupi/session.conf` | Idle lock, start dunst/picom |
| `~/.config/nirupi/status.conf` | Status bar segments, weather, cache |
| `~/.config/nirupi/agents.conf` | opencode profiles |
| `~/.config/nirupi/browser.conf` | Default browser (`nirupi browser set X`) |

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
bash ./install.sh --verify
```

- Missing status icons? Install the Nerd Font (answered during install) or
  re-run `./install.sh --theme-only`.
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
