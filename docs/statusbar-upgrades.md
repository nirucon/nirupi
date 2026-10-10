# Statusbar upgrades (Arch/Omarchy, Debian, Void)

NIRUPI ships the same Bash statusbar on all three distributions. The user-owned
`~/.config/nirupi/status.conf` is never replaced by this updater.

From a current NIRUPI source checkout:

```bash
bash tools/update-statusbar.sh --check
bash tools/update-statusbar.sh --apply
```

If an older installation has no ownership manifest, or the script has been
modified locally, the updater refuses to overwrite it. Inspect the differences
first, then explicitly opt in:

```bash
bash tools/update-statusbar.sh --adopt
```

An existing script is backed up under
`~/.local/state/nirupi/statusbar-backups/` (or `$XDG_STATE_HOME/nirupi`).
The update does not terminate a live DWM session. Log out and log in to activate
the new script; avoid launching duplicate statusbar writers.

The full installer still uses its checksum-protected managed-helper mechanism.
A clean profile receives 0.2-second music frames and three scroll passes;
existing user configuration is preserved, including older scroll preferences.

Run the isolated smoke test:

```bash
bash tests/statusbar-upgrade.sh
```

This smoke test is distro-neutral. Real login/session behavior still needs
validation on each target distro before a stable release.
