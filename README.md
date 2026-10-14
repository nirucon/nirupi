# NIRUPI — NIRU Noir

Minimal, modular **Suckless** desktop environment for **Arch/CachyOS/Omarchy**, **Void Linux (glibc)** and **Debian**. It bundles patched `dwm`, `dmenu`, `st` and `slock`, a unified dark **NIRU Noir** theme, an X11 session, a status bar, launchers and an optional SDDM theme.

**Version:** see `VERSION` · **Status:** beta, actively evolving.

> **Disclaimer.** This is the personal setup of **Nicklas Rudolfsson (NIRUCON)**. It is shared as-is and anyone is welcome to try it, but you install it at your own risk. It makes real changes to your user environment and, with explicit confirmation, to system packages and the display manager. Read the plan output before applying.

## Highlights (v0.3)

- **Non-destructive migration.** Existing Suckless/NIRUPI configs are merged, never deleted. Modified files are preserved and get a sibling `*.nirupi-new` proposal.
- **Safe legacy archival.** Foreign `dwm`/`dmenu`/`st` binaries and symlinks are moved to `~/.local/state/nirupi/legacy/<run>/` with a verifiable backup instead of aborting the install.
- **Unified rollback.** `nirupi rollback --all` restores user configuration *and* binary links from timestamped manifests.
- **Single theme source of truth.** `vendor/noir/theme/tokens.env` drives terminals (`st`, `kitty`, `alacritty`), shell (`fish`), TUI tools (`tmux`, `lazygit`, `micro`, `aerc`), GTK/Qt and browser dark mode.
- **Optional extra apps.** Add your own packages and Git repositories through `~/.config/nirupi/apps.conf`.
- **Idempotent and safe to re-run.** Every write goes through a checksum manifest and a timestamped backup.

## Requirements

- x86_64 only. Void **musl** is not supported (glibc required).
- Run `--apply` from a **local text TTY**, logged out of any graphical session, and never over SSH.
- `--apply` installs packages with your native package manager, so `sudo` is required.

## Fresh install

```sh
git clone https://github.com/nirucon/nirupi.git
cd nirupi
bash ./install.sh --plan          # read-only: review everything
bash ./install.sh --doctor        # diagnose fonts, tools, theme
bash ./install.sh --apply --session startx   # or: --session sddm
```

Or bootstrap directly (clones into `~/Git/nirupi`):

```sh
curl -fsSL https://raw.githubusercontent.com/nirucon/nirupi/main/bootstrap.sh | bash -s -- --plan
```

The installer asks before any change, and separately asks for the privileged `slock` and SDDM setup. The installed `dwm` lives in `~/.local/lib/nirupi/`, so `/usr/local/bin/dwm` is left untouched.

## Upgrade an existing system

```sh
cd ~/Git/nirupi
git pull --ff-only
bash ./tests/smoke.sh
bash ./install.sh --diff          # what will change (configs + theme)
bash ./install.sh --plan
# then, from a local TTY:
bash ./install.sh --apply
```

Upgrading an old Suckless or NIRUPI install is safe: binaries are archived, merged configs are upgraded in place, and customized configs are preserved. Existing `dwm` configs that you edited take precedence and are never overwritten.

## Rollback

All rollbacks write nothing outside `~/.local/state/nirupi/` and `$HOME`, require a local TTY, and ask for confirmation.

```sh
nirupi rollback --all                 # latest config backup + latest binary links
nirupi rollback --configs 20260101-000000-1234
nirupi rollback --binaries            # only the six NIRUPI binary links
```

From the source checkout the equivalent is `bash ./install.sh --rollback` (binary links) and `bash ./migrate-desktop.sh --rollback RUN_ID` (legacy desktop files). Packages, SDDM and system files are **not** reverted.

## Custom apps and repositories

Create `~/.config/nirupi/apps.conf` (see `custom_apps.conf.example`):

```ini
package=htop
package-debian=foo bar
package-arch=baz
repo=https://github.com/user/somerepo.git|~/Git/somerepo|make && sudo make install
```

If the file is absent, installation runs non-interactively with the default package set. Only HTTPS/SSH URLs are accepted and package names are validated.

## Commands

| Command | Purpose |
|---|---|
| `./install.sh --plan` | Read-only plan |
| `./install.sh --apply --session sddm\|startx` | Install/upgrade |
| `./install.sh --doctor` | Font/tool/theme diagnostics |
| `./install.sh --verify` | Verify installed artifacts |
| `./install.sh --diff` | Migration + theme diff |
| `./install.sh --theme-only` | Re-apply NIRU Noir only |
| `./install.sh --update-dots` | Update dotfiles only |
| `./install.sh --history` / `--rollback` | Binary snapshots / restore links |
| `nirupi theme apply\|status\|diff` | Theme shortcuts |
| `nirupi migrate plan` / `nirupi migrate dwm --rebuild` | Migration report / DWM rebuild |
| `nirupi rollback --all\|--configs RUN\|--binaries` | Unified rollback |
| `nirupi browser status\|set\|reset` | Browser resolver |
| `nirupi updates --refresh` | Update counter cache |

## Theming

NIRU Noir uses a single palette in `vendor/noir/theme/tokens.env`. `nirupi theme apply` (or `./install.sh --theme-only`) deploys it across:

- Terminals: `st`, `kitty`, `alacritty`
- Shell: `fish`
- TUI: `tmux`, `lazygit`, `micro`, `aerc`
- Desktop: `dunst`, `picom`, `rofi`, `cmus`, GTK 2/3/4
- Session: `GTK_THEME=Adwaita:dark`, `QT_STYLE_OVERRIDE=kvantum`, `COLORTERM=truecolor`
- Browser: `~/.config/brave-flags.conf` (`--force-dark-mode`)

`tests/noir-consistency.sh` verifies that every terminal shares the exact tokens palette.

## Development and testing

```sh
bash tests/smoke.sh          # full, non-destructive regression suite
bash tests/compile-suckless.sh
bash tests/migration.sh
bash tests/migrate-engine.sh
bash tests/theme.sh
```

## License and author

Author: **Ing Leif Nicklas Rudolfsson** (NIRUCON). Bundled third-party sources (Suckless tools, themes) retain their own licenses; consult the included license files before redistribution.
