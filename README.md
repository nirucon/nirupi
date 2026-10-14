# NIRUPI — NIRU Noir

A personal, minimal **Suckless** X11 desktop for **Arch/CachyOS**,
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

**Manual:** a short day-to-day guide is in [`docs/USAGE.md`](docs/USAGE.md), changes in [`CHANGELOG.md`](CHANGELOG.md).
Physical validation steps are in [`docs/TEST-CHECKLIST.md`](docs/TEST-CHECKLIST.md).

## What it does

- Installs and builds patched `dwm`/`dmenu`/`st`/`slock` into `~/.local`
  (`/usr/local/bin/dwm` stays untouched).
- dwm 6.8 with a hand-integrated bar/session patch set: **status on all
  monitors**, **bar padding**, **tag glyphs**, **terminal swallow**,
  **actual fullscreen**, **jump to urgent** and **layout cycling** (plus the
  existing pertag/gaps/scratchpad/centered-master).
- Status bar with **Noir colors and clickable segments** (agent, volume,
  weather, network, updates, Nextcloud); Nextcloud status without a tray.
- Applies the NIRU Noir dark theme everywhere: terminals, fish, TUI tools
  (`tmux`, `lazygit`, `micro`, `aerc`), GTK/Qt, browsers and the status bar.
  `st`/`dmenu` follow the theme live via **Xresources**, and **rofi, dunst and
  the SDDM theme are generated from the tokens**. Opt-in **wallpaper-driven
  theme** (`nirupi theme wallpaper IMAGE`) and built-in palettes
  (`nirupi theme list|preview|set noir|warm|cool`).
- **Idle ladder**: dim → lock → DPMS off → suspend (each optional), lock on
  suspend, and a Noir lock wrapper (`nirupi lock`).
- **Logout confirmation** (`Super+Shift+q`) and a **night light** toggle
  (`Super+n`, gammastep/redshift).
- Web apps open in **Helium** (Chromium app mode); manage them with
  `nirupi webapp add|list|remove NAME URL`. Helium is provisioned automatically
  (Debian apt repo, Arch AUR helper, otherwise the official tarball) with
  firefox/brave/chromium as fallback.
- Workspace tags use glyphs (browser · AI agents · folder · terminals · chat).
- Clones your default repositories (`nirupresence`, `nirunote`, `nplay`) into
  `~/Git/` on install and updates them on `--update-dots`.
- **Window switcher**, **gaps toggle**, **real fullscreen**, a **lock-screen
  clock with an AFK timer**, a **Noir screensaver** (runic hostname, locks to a
  blurred screen on input), a **power menu with timers** (`Super+Shift+q`), a
  **calendar** and **system-update** pop-up, **caffeine** (stay awake),
  **focus/DND**, **screen recording**, **automatic clipboard history**, a
  **night-light cycle**, **keyboard-layout and touchpad toggles**, **day/night
  theme**, and quick launch for `nirunote`/`nplay`. See
  [`docs/FEATURES.md`](docs/FEATURES.md).
- Installs **opencode** and wires `nirupi agent` + a control center / keybinding
  cheat-sheet (`Super+a`, `Super+/`, ``Super+` ``).
- Migrates an existing system **non-destructively**: configs are merged, foreign
  binaries are archived (never deleted), customized files are preserved.
- Provides safe, manifest-based rollback of configs and binary links.
- **CI** (smoke on Debian + Arch, shellcheck), `nirupi doctor --fix`, and
  optional scheduled backups (`nirupi backup --schedule`).
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
nirupi theme apply|status|diff|list|preview PALETTE|set PALETTE
nirupi theme wallpaper IMAGE|mode noir|wallpaper|palette
nirupi migrate plan|dwm --rebuild     nirupi agent [profile]
nirupi menu | nirupi keys | nirupi lock | nirupi webapp add|list|remove
nirupi backup [--schedule|--unschedule]
nirupi status --once|--json          nirupi gc --dry-run|--yes
nirupi update
nirupi doctor [--fix]
nirupi rollback --all|--configs RUN|--binaries
nirupi browser status|set|reset       nirupi updates --refresh
```

Keybindings: `Super+Return` terminal, `Super+b` browser, `Super+a` agent,
`Super+Shift+h` keybinding palette, `Super+Shift+m` control center, `Super+Esc` lock,
`Super+Shift+q` log out, `Super+n` night light, `Super+F11` fullscreen,
`Super+Ctrl+,`/`Super+Ctrl+.` cycle layouts, `Super+Shift+w` next wallpaper,
`Super+F5` reload theme colors. (On US layouts `Super+/` and ``Super+` `` also work.)
The full list is generated in [`docs/KEYBINDINGS.md`](docs/KEYBINDINGS.md).

## Development

```sh
bash tests/smoke.sh        # full non-destructive regression suite
bash tests/compile-suckless.sh
```

## Author

**Nicklas Rudolfsson (NIRUCON)** — <https://github.com/nirucon>.
Made primarily for my own machines; contributions and forks are welcome under
the MIT license.
