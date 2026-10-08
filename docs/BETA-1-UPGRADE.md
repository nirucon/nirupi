# NIRUPI 0.2.0-beta.1 – safe upgrade from alpha.32

**Baseline:** NIRUPI 0.2.0-alpha.32, successfully tested on physical Debian 13 (INGWAZ).

## Scope

- `./install.sh --verify` checks managed binary symlinks, consistent installed version, desktop entry and essential configs; read-only, including via SSH.
- `./install.sh --history` lists pre-upgrade binary-link snapshots.
- `./install.sh --apply --session sddm` preserves existing settings and performs the same staged build as alpha.32; it takes a pre-upgrade snapshot before package changes.
- `./install.sh --rollback` restores **only the six NIRUPI-managed binary symlinks** to their pre-upgrade targets. Requires local TTY and explicit confirmation. It does not roll back user configs, SDDM, system packages, or manifests.
- Snapshots stored in `~/.local/state/nirupi/release-snapshots/` (or XDG_STATE_HOME equivalent). Do not delete previous release directories if rollback may be needed.

## Procedure (Fish-compatible)

```fish
cd ~/Git/nirupi
command git pull --ff-only
command bash ./tests/smoke.sh
command bash ./install.sh --verify
command bash ./install.sh --plan --session sddm
```

Log out of DWM, switch to a local text TTY and then:

```fish
cd ~/Git/nirupi
command bash ./install.sh --apply --session sddm
command bash ./install.sh --verify
command bash ./install.sh --history
```

After successful verification, log in via SDDM and test DWM, Rofi, Kitty, dmenu, status, sound, screenshot, lock/unlock and restart. Preserve SSH as a recovery channel.

**If upgrade fails:** do not reboot blindly. Inspect the error and run `./install.sh --history`. `--rollback` only restores binary links and should not be treated as full system rollback. Never run it while DWM is active.

## Known limitations

- No end-to-end VM or physical beta.1 installation verified yet.
- SDDM and system package changes cannot be reverted automatically.
- Existing personal DWM config takes precedence during build; this is intentional.
- Alpha.32 and beta.1 use the same bundled NIRU Noir configuration and core desktop layout.
