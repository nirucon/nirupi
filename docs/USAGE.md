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
| `Super+/` | **Keybinding palette** (search everything) |
| ``Super+` `` | **Control center** |
| `Super+Esc` | Lock (slock) |
| `Super+Shift+w` | Next wallpaper |
| `Super+F5` | Reload theme colors (Xresources) |
| `Super+q` | Close focused window |
| `Super+Shift+q` | Quit dwm (end session) |

The full, searchable list is `Super+/` (or `nirupi keys`). It clearly marks
**apps** vs **keybindings**: pressing Enter on an app launches it, on a
keybinding it copies the shortcut.

## The status bar

Segments (left to right): agent, media counts, volume, mic-mute, now playing,
network, Nextcloud, battery, temperature, DND, recording, updates, kernel,
host, weather (Ljungskile), date, time.

Clicks (the sections that are clickable):

- **Agent icon** → opencode · **Volume** → scroll to change, click to mute
- **Weather** → forecast · **Network** → Wi‑Fi menu
- **Updates** → check updates · **Nextcloud** → open the client

Tune it in `~/.config/nirupi/status.conf` (this file is yours and is never
overwritten): toggle segments with `SHOW_*`, set weather coordinates, or change
cache intervals. Restart the session to re-read it.

## Control center — ``Super+` ``

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
cd ~/Git/nirupi
git pull --ff-only
bash ./install.sh --diff      # what will change
bash ./install.sh --plan
# then from a local TTY:
bash ./install.sh --apply
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
- `~/.local/state/nirupi/installed.env` records version and schema;
  `~/.local/state/nirupi/legacy/` holds archived old binaries.

## Where things live

- Binaries/links: `~/.local/bin`, versioned builds under `~/.local/lib/nirupi/`.
- User config: `~/.config/<app>/` and `~/.config/nirupi/`.
- State/backups/legacy: `~/.local/state/nirupi/`.
- DWM config: `~/.config/suckless/dwm/config.h`.
