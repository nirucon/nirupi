# NIRUPI 0.2.0-beta.4 – browser and upgrade notes

- New installations: Super+B executes `nirupi-browser`.
- Existing DWM config: preserved exactly; INGWAZ `helium` continues to work.
- Browser executable resolution: configured name, then helium/helium-browser/firefox/brave/chromium, then xdg-open.
- No `eval`, no shell sourcing, no package-name assumptions, no automatic AUR access.
- `nirupi browser set helium` creates `~/.config/nirupi/browser.conf`.
- `nirupi browser reset` renames that config to a timestamped backup.
- Existing GTK and icon preferences remain untouched.
- Installation still requires local TTY, and system-level changes are not covered by binary rollback.
- Publish via `bash ./publish-github.sh` from extracted release; review diff and type PUBLISH.
- Debian: `git pull --ff-only`, `bash ./install.sh --plan`, then from TTY `bash ./install.sh --apply`, then `bash ./install.sh --verify`.
