# nirupi

My personal, minimal **Suckless** X11 desktop for **Arch/CachyOS**, **Void Linux** and **Debian**.

It builds patched `dwm`, `dmenu`, `st` and `slock` into `~/.local`, keeps the
whole desktop on one theme palette, and wires up an X11 session, a status bar,
launchers and an optional SDDM theme. Themes shipped: Noir, Satie, Carl
Larsson, Hackerman, Nord dark.

This is the everyday setup of **Nicklas Rudolfsson (NIRUCON)**, tuned for my
own machines. It is public so anyone can read, learn from or try it — but it
is built for my workflow, not as a general-purpose distribution. **Use it at
your own risk.** It changes your user environment and, with explicit
confirmation, system packages and the display manager. Read the `--plan`
output before applying anything.

## Install

```sh
git clone https://github.com/nirucon/nirupi
cd nirupi
./install.sh --plan     # see exactly what it would change
./install.sh --apply
```

## Everyday use

```sh
nirupi theme set noir      # restyle the whole desktop from one palette
nirupi doctor              # check the setup, --fix to repair
nirupi status --once       # bar values
nirupi update              # pull in the latest nirupi + dots
nirupi rollback --all      # undo the last change
```

Keybindings: `Super+Shift+p` launcher, `Super+Enter` terminal, `Super+Ctrl+t`
theme picker, `Super+Shift+q` power menu, `Super+Alt+k` full keybinding table.

## Where things are

| | |
| --- | --- |
| Day-to-day guide | [`docs/USAGE.md`](docs/USAGE.md) |
| Everything it sets up | [`docs/FEATURES.md`](docs/FEATURES.md) |
| Every keybinding | [`docs/KEYBINDINGS.md`](docs/KEYBINDINGS.md) |
| Manual test steps | [`docs/TEST-CHECKLIST.md`](docs/TEST-CHECKLIST.md) |
| Changes | [`CHANGELOG.md`](CHANGELOG.md) |

Your own packages and repos go in `~/.config/nirupi/apps.conf` — copy
`custom_apps.conf.example` next to it to start.

## License

MIT (see [`LICENSE`](LICENSE)). The bundled Suckless tools and third-party
themes are not mine and keep their own licenses, also listed there.

Fork it, read it, take what you want. It is made for my machines, so expect
it to fit them better than yours.
