# NIRUPI — NIRU Noir

Minimal, modular Suckless desktop environment for **Debian 13**, **Void Linux (glibc)** and **Arch/CachyOS**. Bundles patched DWM, dmenu, st and slock, an X11 session, status bar, launchers and optional SDDM theme.

**Version:** 0.2.0-beta.5 · **Status:** beta, physical Void test pending for this release.

## Installation

Run as a normal user from a **local text TTY** (not an active graphical session or SSH connection):

```sh
bash ./install.sh --plan
bash ./install.sh --doctor
bash ./install.sh --apply --session sddm
```

Use `--session startx` instead if appropriate. The installer asks before making changes and separately asks for privileged slock and SDDM setup. Existing user configurations are preserved; an existing DWM `config.h` takes precedence. The installed NIRUPI DWM lives in `~/.local/lib/nirupi/`, leaving `/usr/local/bin/dwm` untouched.

## Commands

`nirupi doctor`, `nirupi version`, `nirupi browser status`, `nirupi updates`, `nirupi keys`. `nirupi --version` is also supported. `./install.sh --history` and `./install.sh --rollback` provide limited NIRUPI-managed rollback; they do not revert system package transactions.

## Void Linux

Void uses XBPS and runit. NIRUPI uses the Void-specific `fish-shell` package name and checks requested XBPS packages before the transaction. SDDM service activation is not performed automatically on Void; check with `sudo sv status sddm` when applicable. Only x86_64 glibc Void is supported at present.

## Development and licensing

Author: **Ing Leif Nicklas Rudolfsson**. Run `bash tests/smoke.sh` for regression checks. Bundled third-party sources retain their own licenses; consult the included license files before redistribution. See `docs/BETA5-VOID.md` for validation details.
