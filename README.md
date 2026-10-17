# nirupi

My personal, minimal **Suckless** X11 desktop for **Arch Linux**, **Void Linux** and **Debian**.

It builds patched `dwm`, `dmenu`, `st` and `slock` into `~/.local`, keeps the
whole desktop on one theme palette, and wires up an X11 session, a status bar,
launchers and an optional SDDM theme.

This is the everyday setup of **Nicklas Rudolfsson (NIRUCON)**, tuned for my
own machines. It is public so anyone can read, learn from or try it, but it is
built for my workflow, not as a general purpose distribution. Use it at your
own risk. It changes your user environment and, with explicit confirmation,
system packages and the display manager. Read the `--plan` output before
applying anything.

## Themes

Fourteen palettes. Switch one and the whole desktop restyles live: terminals,
fish, tmux, GTK/Qt, rofi, dunst, browsers and the status bar. Pick one with
`nirupi theme set NAME`, or `Super+Ctrl+t` for a picker that previews them.

| Theme | What it looks like |
| --- | --- |
| `noir` | Cold near black monochrome (default) |
| `Noir-warm` | Warm, low blue variant |
| `Noir-cool` | Cool, blue leaning variant |
| `Noir-day` | Light warm paper, readable in daylight |
| `Satie` | Flat monochrome graphite, one muted gold accent |
| `Carl-Larsson` | Warm umber, cream and earthy watercolour accents |
| `NIRU-Ink` | Near black ink wash with a single patinated copper accent |
| `Hackerman` | Phosphor green on black, CRT hacker terminal |
| `Amber-CRT` | Monochrome amber phosphor terminal |
| `Commodore-64` | VIC-II blue screen and light blue PETSCII text |
| `Commando` | Field camo at dusk, olive and khaki with hi vis amber |
| `Gruvbox-Dark` | Warm retro groove, soft brown with yellow and orange |
| `Tokyo-Night` | Cool indigo night with blue, magenta and cyan accents |
| `Nord-Dark` | Polar Night blues with Nord frost and aurora accents |

You can also drive a theme from a wallpaper (`nirupi theme wallpaper IMAGE`).

## What it does

**Desktop.** dwm 6.8 with right/left stack, floating, monocle, centered master
and a window switcher. Gaps toggle, real fullscreen, terminal swallow, urgent
jump, scratchpad, per monitor tags, and status on every monitor.

**Session and power.** A lock screen and a screensaver that locks to a blurred
screen on input, an idle ladder that dims then locks then turns the screen off
then suspends, a power menu with timers, log out confirmation, and a night
light toggle.

**Everyday tools.** Calendar and update pop ups (system packages, AUR and Git
checkouts under `~/Git`), clipboard history, caffeine (stay awake), focus/DND,
screen recording, keyboard layout and touchpad toggles, and SSH host jumping.

**Your apps.** Web apps open in Helium in Chromium app mode (`nirupi webapp
add NAME URL`). Your own packages and repos go in
`~/.config/nirupi/apps.conf`. It can clone your default repositories into
`~/Git/` and keep them updated.

**Capture and agents.** Screenshot and region capture menus, and shortcuts to
ask an agent about a selection, a region or a command.

**Keeping it healthy.** `nirupi doctor --fix`, `nirupi gc`, `nirupi backup
--schedule`, `nirupi rollback`, and `nirupi update`.

## Install

```sh
git clone https://github.com/nirucon/nirupi
cd nirupi
./install.sh --plan     # see exactly what it would change
./install.sh --apply
```

## Common commands

```sh
nirupi theme set noir      # restyle the whole desktop
nirupi doctor --fix        # check the setup and repair it
nirupi status --once       # bar values
nirupi webapp add mail https://mail.example.com
nirupi update              # pull in the latest nirupi and dots
nirupi repos pull --all    # fast-forward clean Git checkouts in ~/Git
nirupi rollback --all      # undo the last change
```

Handy keys: `Super+Shift+p` launcher, `Super+Enter` terminal, `Super+Ctrl+t`
theme picker, `Super+Shift+q` power menu, `Super+w` window switcher,
`Super+Alt+k` full keybinding table.

## Where things are

| | |
| --- | --- |
| Day to day guide | [`docs/USAGE.md`](docs/USAGE.md) |
| Everything it sets up | [`docs/FEATURES.md`](docs/FEATURES.md) |
| Every keybinding | [`docs/KEYBINDINGS.md`](docs/KEYBINDINGS.md) |
| Manual test steps | [`docs/TEST-CHECKLIST.md`](docs/TEST-CHECKLIST.md) |
| Changes | [`CHANGELOG.md`](CHANGELOG.md) |

## License

MIT (see [`LICENSE`](LICENSE)). The bundled Suckless tools and third party
themes are not mine and keep their own licenses, also listed there.

Fork it, read it, take what you want. It is made for my machines, so expect it
to fit them better than yours.
