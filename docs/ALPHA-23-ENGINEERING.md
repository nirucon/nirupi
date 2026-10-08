# Alpha.23 — Managed NIRU Noir configuration upgrades

- New checksum manifest `managed-configs.tsv` covers DWM config, Rofi theme, per-app dotfiles, Xresources and user X11 launchers.
- A file is upgraded only when it is tracked and still matches its last installed SHA-256.
- User edits, symlinks, foreign files and legacy untracked configs are preserved.
- Backups are written before replacing managed files, and executable permissions are repaired.
- The installer still builds the bundled DWM config; user-edited DWM config is preserved for reference and **not compiled automatically**. This mismatch requires an explicit supported customization workflow.
- Full rollback, system-level manifest, GitHub source publication, real graphical tests and distro package verification remain open.
