# NIRUPI — NIRU Noir

A personal, minimal **Suckless** X11 desktop for **Arch/CachyOS/Omarchy**,
**Void Linux (glibc)** and **Debian**. It bundles patched `dwm`, `dmenu`, `st`
and `slock`, one unified dark **NIRU Noir** theme, an X11 session, a status bar,
launchers and an optional SDDM theme.

> **Personal project.** This is the everyday setup of **Nicklas Rudolfsson
> (NIRUCON)**. It is shared openly so anyone can read, learn from or try it —
> you install it at your own risk. It changes your user environment and, with
> explicit confirmation, system packages and the display manager. Read the
> `--plan` output first.

**License:** MIT (see `LICENSE`). The bundled Suckless tools and third-party
themes are **not** mine and keep their own licenses (also listed in `LICENSE`).

**Manual:** a short day-to-day guide is in [`docs/USAGE.md`](docs/USAGE.md).
Physical validation steps are in [`docs/TEST-CHECKLIST.md`](docs/TEST-CHECKLIST.md).

## What it does

- Installs and builds patched `dwm`/`dmenu`/`st`/`slock` into `~/.local`
  (`/usr/local/bin/dwm` stays untouched).
- Status bar with **Noir colors and clickable segments** (agent, volume,
  weather, network, updates, Nextcloud); Nextcloud status without a tray.
- Applies the NIRU Noir dark theme everywhere: terminals, fish, TUI tools
  (`tmux`, `lazygit`, `micro`, `aerc`), GTK/Qt, browsers and the status bar.
  Opt-in **wallpaper-driven theme** (`nirupi theme wallpaper IMAGE`).
- Automatic **screen lock** after 10 min idle (configurable).
- Installs **opencode** and wires `nirupi agent` + a control center / keybinding
  cheat-sheet (`Super+a`, `Super+/`, ``Super+` ``).
- Migrates an existing system **non-destructively**: configs are merged, foreign
  binaries are archived (never deleted), customized files are preserved.
- Provides safe, manifest-based rollback of configs and binary links.
- Optional extra packages and Git repositories via `~/.config/nirupi/apps.conf`.

## Requirements

- x86_64; Void **musl** unsupported. Run `--apply` from a **local text TTY**,
  logged out of any graphical session and never over SSH. `sudo` is required.

## Install

```sh
git clone https://github.com/nirucon/nirupi.git
cd nirupi
bash ./install.sh --plan                    # read-only review
bash ./install.sh --doctor                  # diagnose fonts/tools/theme
bash ./install.sh --apply --session startx  # or --session sddm
```

Or bootstrap (clones into `~/Git/nirupi`):

```sh
curl -fsSL https://raw.githubusercontent.com/nirucon/nirupi/main/bootstrap.sh | bash -s -- --plan
```

## Upgrade

```sh
cd ~/Git/nirupi
git pull --ff-only
bash ./install.sh --diff     # what changes
bash ./install.sh --plan
# then from a local TTY:
bash ./install.sh --apply
```

## Rollback

Requires a local TTY and confirmation; only touches `$HOME` and
`~/.local/state/nirupi/`.

```sh
nirupi rollback --all                 # latest config backup + binary links
nirupi rollback --configs <RUN_ID>    # one config backup
nirupi rollback --binaries            # binary links only
```

## Customize

- **Apps/repos:** copy `custom_apps.conf.example` to `~/.config/nirupi/apps.conf`
  and list extra `package=`, `package-<distro>=` and `repo=URL|DEST|BUILD`.
- **Theme:** NIRU Noir is generated from `vendor/noir/theme/tokens.env`.
  Re-apply anytime with `./install.sh --theme-only` or `nirupi theme apply`.
- **Dots only:** `./install.sh --update-dots`.

## Commands

```
./install.sh --plan|--apply|--doctor|--verify|--diff|--history|--rollback
./install.sh --theme-only|--update-dots|--migrate|--dry-run
nirupi theme apply|status|diff|wallpaper IMAGE|mode noir|wallpaper
nirupi migrate plan|dwm --rebuild     nirupi agent [profile]
nirupi menu | nirupi keys | nirupi backup
nirupi rollback --all|--configs RUN|--binaries
nirupi browser status|set|reset       nirupi updates --refresh
```

Keybindings: `Super+Return` terminal, `Super+b` browser, `Super+a` agent,
`Super+F1` keybinding palette, `Super+F2` control center, `Super+Esc` lock,
`Super+Shift+w` next wallpaper, `Super+F5` reload theme colors.
(On US layouts `Super+/` and ``Super+` `` also work.)

## Development

```sh
bash tests/smoke.sh        # full non-destructive regression suite
bash tests/compile-suckless.sh
```

## Author

**Nicklas Rudolfsson (NIRUCON)** — <https://github.com/nirucon>.
Made primarily for my own machines; contributions and forks are welcome under
the MIT license.
