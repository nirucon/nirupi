# NIRUPI — a NIRU desktop

A personal, minimal **Suckless** X11 desktop for **Arch/CachyOS**,
**Void Linux (glibc)** and **Debian**. It bundles patched `dwm`, `dmenu`, `st`
and `slock`, a set of unified **themes** (Noir, Satie, Carl Larsson, Hackerman,
Nord dark) that restyle the whole desktop from one palette, an X11 session, a
status bar, launchers and an optional SDDM theme.

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
- Status bar with **theme colours and clickable segments** (agent, volume,
  weather, network, updates, Nextcloud); Nextcloud status without a tray.
- Applies the theme everywhere: terminals (`kitty`, `alacritty`, `st`), fish,
  TUI tools (`tmux`, `lazygit`, `micro`, `aerc`, `cmus`), GTK/Qt, rofi, dunst,
  browsers and the status bar. Everything is generated from a single palette
  (`vendor/noir/theme/*.env`), so **switching a theme restyles all of it live**
  (dunst colours live in a `dunstrc.d` drop-in, so your own notification
  settings are kept). Ship-with themes: **Noir** (default), **Satie**
  (monochrome graphite), **Carl Larsson** (warm umber/watercolour),
  **Hackerman** (phosphor green), **Nord dark** and **Noir day** (light
  paper), plus `warm`/`cool` variants: `nirupi theme list|preview NAME|set NAME`
  or the **theme picker** (`Super+Ctrl+t`, which shows the active theme and a
  description). Opt-in **wallpaper-driven theme** (`nirupi theme wallpaper IMAGE`).
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
  **night-light cycle**, **keyboard-layout and touchpad toggles**, and quick
  launch for `nirunote`/`nplay`. Themes are always chosen **manually**. See
  [`docs/FEATURES.md`](docs/FEATURES.md).
- Installs **opencode** and wires `nirupi agent` + a control center / keybinding
  cheat-sheet (`Super+a`, `Super+/`, ``Super+` ``).
- **Quality of life:** capture (`Super+Ctrl+Print`: region/window/full +
  annotate + OCR-to-clipboard), ask the agent about the current selection
  (`Super+Ctrl+a`) or a screen region (`Super+Ctrl+s`), an **AI command** helper
  (`Super+Ctrl+c`: describe a task, review the suggested command, run on
  Enter), an **SSH/host picker** (`Super+s`, `~/.ssh/config` + Tailscale), an
  emoji picker, clipboard transforms, an audio-output picker, **fish + bash
  completions**, `nirupi help COMMAND`, a man page, `nirupi edit TOPIC` and
  `nirupi reload` (rebuild dwm only if needed + restart in place).
  **Per-workspace wallpapers** (`~/.config/nirupi/wallpapers.conf`) switch
  instantly on tag switch and toggle from the control center. dwm gains smart
  gaps/borders, an **in-place restart** (`Super+Ctrl+Shift+r`) and mouse-drag of
  the master factor (`Super+Button2`).
- Migrates an existing system **non-destructively**: configs are merged, foreign
  binaries are archived (never deleted), customized files are preserved.
- **Clean-install ready:** installs the pieces a vanilla system needs (X input
  driver, `mesa`, `alsa-ucm-conf`, the PipeWire↔ALSA bridge, `man-db`,
  `bash-completion`, XDG portals), auto-detects CPU/GPU for microcode +
  VA-API/Vulkan, and enables `tailscaled`/`bluetooth`. On Arch it can (opt-in)
  install an AUR helper (`paru-bin`) so AUR apps install via the package manager.
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
- **Theme:** every colour comes from `vendor/noir/theme/*.env` (one palette per
  theme). Pick with `nirupi theme menu` (`Super+Ctrl+t`; shows the active theme
  and a description), apply a name with `nirupi theme set NAME`, or re-apply
  with `./install.sh --theme-only`. Add your own palette by dropping `Name.env`
  in that directory (same schema).
- **Dots only:** `./install.sh --update-dots`.

## Commands

```
./install.sh --plan|--apply|--doctor|--verify|--diff|--history|--rollback
./install.sh --theme-only|--update-dots|--migrate|--dry-run
nirupi theme apply|status|diff|list|preview NAME|set NAME|menu
nirupi theme wallpaper IMAGE|mode noir|wallpaper|palette
nirupi wallpaper set FILE|next|per-tag on|off|toggle|status
nirupi ssh                              nirupi edit [TOPIC]     nirupi reload
nirupi migrate plan|dwm --rebuild     nirupi agent [profile]
nirupi menu | nirupi keys | nirupi lock | nirupi webapp add|list|remove
nirupi backup [--schedule|--unschedule]
nirupi status --once|--json          nirupi gc --dry-run|--yes|--legacy
nirupi update
nirupi doctor [--fix]
nirupi rollback --all|--configs RUN|--binaries
nirupi browser status|set|reset       nirupi updates --refresh
```

Keybindings: `Super+Return` terminal, `Super+b` browser, `Super+a` agent,
`Super+Ctrl+a` ask agent about the selection, `Super+Ctrl+s` ask agent about a
screen region, `Super+Ctrl+c` AI command, `Super+s` SSH hosts,
`Super+Ctrl+t` theme picker,
`Super+Shift+h` keybinding palette, `Super+Alt+k` full keybinding table (TUI),
`Super+Shift+m` control center, `Super+Ctrl+Print` capture menu,
`Super+Esc` lock,
`Super+Shift+q` log out, `Super+n` night light, `Super+Shift+e` fullscreen,
`Super+Ctrl+,`/`Super+Ctrl+.` cycle layouts, `Super+Shift+w` next wallpaper,
`Super+Shift+r` reload theme colours. (On US layouts `Super+/` and ``Super+` `` also work.)
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
