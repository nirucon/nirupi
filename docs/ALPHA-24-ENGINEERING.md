# Alpha.24 — DWM configuration build consistency

## Fix

The installer previously preserved `~/.config/suckless/dwm/config.h` but **always compiled the bundled `vendor/suckless/dwm/config.h`**, leaving personal keybindings and layouts unapplied. It also could update the managed config after compilation, leaving config and binary out of sync.

The staged build now uses an existing regular user `config.h` if present, otherwise the bundled NIRU Noir config. It refuses symlinks and non-regular config paths. It preserves an existing user config after the build, so the installed binary and config correspond to the same source. Compilation failures occur in temporary build directories before deploying any new binary.

## Limitations

- A customized `config.h` may reference additional C files not bundled with NIRUPI; such builds will fail safely, with existing executables untouched.
- Existing DWM config is intentionally not auto-migrated. Updating it requires an explicit migration/rebuild workflow.
- No full distro-specific compile, X11 session, SDDM, or graphical appearance test has been completed.
- Complete source tree publication to GitHub is still pending.
