# NIRUPI 0.2.0-beta.3 — GTK appearance

- PCManFM on Debian 13 links to GTK 3. LXAppearance confirmed `Adwaita-dark` works.
- Clean profiles: initialize GTK 3 `Adwaita-dark`, GTK 2 when theme is present.
- Existing GTK configuration is preserved during installation/upgrades, including LXAppearance settings.
- `nirupi appearance status` reports active preferences.
- `nirupi appearance apply noir` explicitly applies the theme and saves a snapshot.
- `nirupi appearance restore` restores the latest snapshot.
- Icon selection prefers installed `Papirus-Dark`, then `Tela-black`, otherwise `Adwaita`. No unverified icon package is installed automatically. The Adwaita fallback is not fully monochrome.
- GTK 4/libadwaita applications may use separate dark-mode preferences; this release does not override them.
- Do not run the full `install.sh --apply` from the graphical session; use a local TTY.
- To deploy only the appearance helper from a trusted checked-out release, copy it to `~/.local/bin/nirupi-appearance` with `install -m 0755`. The full release installer remains the supported upgrade path.
