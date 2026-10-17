# nirupi

**My personal, minimal Suckless X11 desktop for Arch Linux, Void Linux and Debian.**
It builds patched `dwm`, `dmenu`, `st` and `slock` into `~/.local`, puts the
whole desktop on one theme palette, and wires up the session, status bar,
launchers, screenshots, notifications and a small maintenance CLI.

This is the everyday setup of **Nicklas Rudolfsson (NIRUCON)**. It is public so
others can read, learn from or try it, but it is tuned for my machines. Read
`./install.sh --plan` before applying anything.

## Highlights

- **dwm 6.8** with right/left stack, floating, monocle, centered master and
  fibonacci layouts. Gaps, real fullscreen, terminal swallow, scratchpad,
  per-monitor tags and sticky windows.
- **Keyboard first** — 144 documented bindings, no function keys, safe on a
  Swedish layout. See [`docs/KEYBINDINGS.md`](docs/KEYBINDINGS.md).
- **One palette** drives terminals, fish, tmux, GTK/Qt, rofi, dunst, picom,
  browsers, the status bar, the lock screen and SDDM. 14 themes, switch live
  with `Super+Ctrl+T` or `nirupi theme set NAME`.
- **Session and power** — lock screen, screensaver, idle ladder (dim → lock →
  DPMS → suspend), timed power menu and night light.
- **Everyday tools** — launcher, window switcher, clipboard history, calendar,
  update pop-ups, caffeine, focus/DND, screen recording, SSH picker, USB mount.
- **AI, locally controlled** — ask the agent about a selection or screen region,
  generate a command for review, or diagnose the machine with `Super+Ctrl+D`.
- **Small and maintainable** — profiles, a runtime `dwm` rules file, persistent
  layout state, safe config upgrades and rollback.

## Install

```sh
git clone https://github.com/nirucon/nirupi
cd nirupi
./install.sh --plan          # read-only: show profile, packages and changes
./install.sh --apply         # interactive TUI, then a typed INSTALL confirmation
```

Profiles:

| Profile | What it installs |
| --- | --- |
| `minimal` | Desktop, status bar, audio, network and core tools |
| `desktop` | The NIRUPI desktop (default) |
| `full` | Desktop plus the optional application set |

All three profiles install hardware firmware/VA-API best-effort. Optional
applications are installed only when you opt in.

## Common commands

```sh
nirupi theme set noir       # restyle the desktop live
nirupi doctor --fix         # diagnose and repair the setup
nirupi doctor --perf        # bar wakeups, compositor, swap, governor
nirupi tune plan            # reversible sysctl tuning (apply/revert)
nirupi snapshot status      # pre-update snapshot backend
nirupi gc --system          # distro-native cleanup (dry-run by default)
nirupi backup --list        # list config archives (verify/restore too)
nirupi mission work         # open a named workspace/app set
nirupi dwm state            # inspect saved dwm layout
nirupi explain              # diagnose the system with the agent
nirupi update               # update nirupi itself
nirupi rollback --all       # restore configs + binary links
```

Handy keys: `Super+Shift+P` launcher, `Super+Enter` terminal,
`Super+Ctrl+T` theme picker, `Super+Shift+Q` power menu, `Super+W` window
switcher, `Super+Alt+K` full keybinding table, `Super+Ctrl+D` diagnose.

## Where things are

| | |
| --- | --- |
| Day-to-day guide | [`docs/USAGE.md`](docs/USAGE.md) |
| Everything it sets up | [`docs/FEATURES.md`](docs/FEATURES.md) |
| Every keybinding | [`docs/KEYBINDINGS.md`](docs/KEYBINDINGS.md) |
| Manual test steps | [`docs/TEST-CHECKLIST.md`](docs/TEST-CHECKLIST.md) |
| Changes | [`CHANGELOG.md`](CHANGELOG.md) |

## Safety

`--plan` is read-only. `--apply` requires a local TTY, shows a summary and asks
you to type `INSTALL`; Arch and Void can additionally require a typed
`UPGRADE` for a synchronized system upgrade. Existing configs are merged, never
deleted, and foreign binaries are archived. Configuration and binary links can
be rolled back with `nirupi rollback`; package rollback is distro-native.

## License

MIT (see [`LICENSE`](LICENSE)). The bundled Suckless tools and third-party
themes keep their own licenses, also listed there.
