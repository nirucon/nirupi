# NIRUPI v0.4 — "Noir Bar & Agent" (planering, ej committad)

> Status: **implementerad** (se `docs/V0.4-OVERHAUL.md` och
> `docs/TEST-CHECKLIST.md`). Denna fil behålls som beslutslogg.

## Låsta beslut
- Tray: **hoppas över**. App-status löses som bar-segment utan tray.
  Nextcloud visas **automatiskt om det är installerat**.
- Dynamiskt wallpaper-tema: **ja**, opt-in, av som default, togglas med
  keybinding. Får använda **Xresources-patch** på st/dwm/dmenu (ingen rebuild
  per bildbyte). Uppdatera samtidigt vendored suckless till senaste upstream.
- opencode: **installeras alltid**; officiell installer primär, npm/AUR fallback.
- dwm-patchar: **ja, gör allt som behövs** (se E2).
- Kontrollcenter: **tas med i 0.4**.
- Utan: tangentbordslayout-segment, veckodag, sekunder i baren.
- README: kort och saklig — vad det är, vad det gör, hur man använder det, vem
  som gjort det, att det är personligt, MIT, och att Suckless m.fl. inte ägs av
  mig.
- Städning utförd (v0.4-cleanup): tog bort oanvända scripts
  (`___OLD___install-reaper-daw`, `install-ollama-setup`, `arch-maintenance`,
  `cachy-reaper-audio-setup`), `publish-github.sh`, det destruktiva
  `migrate-desktop.sh` (+ test), `compat/nirupi-updates-beta1` (beta.1-shim) och
  gamla ALPHA/BETA/docs. Lade till `LICENSE` (MIT).

## Epics

### E1 — Statusbar 2.0 (Noir Bar)
- Fixa stubbar: `get_cpu`, `get_bluetooth`.
- Temp alltid synlig med `°C`, läs `hwmon`/`coretemp` (fallback thermal).
- Provider-cache med TTL: nätverk (nmcli 15–30s), kernel/host (en gång),
  volym/batteri (kort TTL). Bygg om `build_status_line` till providers.
- Batteritid kvar (energy_now/power_now).
- Mikrofon-mute, DND (dunst pausad), inspelningsindikator.
- Nerd Font-glyfer för vädret (ersätt emoji), aktuell temp.
- `nirupi status --once|--json` för tester.
- Nextcloud-status utan tray — se E6.

### E2 — dwm-patchar (vendored källa)
- Bumpa dwm 6.6 → 6.8, slock 1.6 → 1.7 (säkerhetsfix). st 0.9.3 och dmenu 5.4
  är redan senaste.
- Lägg till: status2d, statuscmd, Xresources, vanitygaps (smartgaps), swallow,
  actualfullscreen, focusurgent, movestack, tagicons, ewmhtags.
- Redan på plats: pertag, centeredmaster, scratchpad, egna rstack/tileleft.
- Undvik: restartsig (tester förbjuder), systray (hoppas över).
- Uppdatera `config.h`-keybindings + tester (dwm-config, compile-suckless).

### E3 — Agent (opencode)
- Installera cross-distro (officiell installer → ~/.local/bin, fallback npm,
  Arch/AUR `opencode-bin`).
- `nirupi agent [codex|deepseek|claude|...]` + dmenu/rofi-väljare.
- `~/.config/nirupi/agents.conf` (endast modellnamn/flaggor, inga nycklar).
- Keybinding `Super+a`; senare agentikon i baren (E2 statuscmd).
- Valfri `~/.config/opencode/`-skellet utan hemligheter + docs.

### E4 — Keybinding-cheat-sheet
- En sanningskälla: generera `~/.local/share/nirupi/keybindings.tsv` från
  `config.h` vid install.
- Primärt: **rofi**-modi (centrerad, Noir-tema, sökbar). Tydlig kategori:
  `⌨ Keybinding` vs `  App` vs `  Funktion`.
- Sekundärt: **fzf-TUI** i centrerad flytande kitty-scratchpad.
- Ersätter/kompletterar `dwm-keybindings.sh`; inga duplicerade listor.

### E5 — Dynamiskt wallpaper-tema (opt-in)
- `wallust` (rekommenderat) eller pywal → palett.
- `nirupi theme mode noir|wallpaper`; sparas i `~/.config/nirupi/theme.mode`.
- Xresources-patch på st/dwm/dmenu → omedelbar färgväxling (`.Xresources` +
  `xrdb -merge`), annars rebuild via migreringsmotorn.
- `Super+Shift+T` togglar; `Super+Shift+W` byter bild + applicerar palett.
- Default = statisk Noir.

### E6 — App-status utan tray (SNI)
- Generisk SNI-läsare `nirupi-sni-status` (läser `org.kde.StatusNotifierItem`
  över session-DBus): `Status` + `IconName` → ok/syncing/error/paused.
- Första användare: **Nextcloud** (DBus SNI; fallback: process + syncjournal/
  logg-mtime). Cachas i baren, göms om ej installerad.
- Återanvändbar för Slack/Telegram/Dropbox/Syncthing m.fl.

### E7 — Session/idle & indikatorer
- Idle/lock: `xss-lock` + `xidlehook` (eller xautolock) → auto slock.
- DND-toggle (`dunstctl`) + indikator.
- Inspelningsindikator (wf-recorder/ffmpeg) klickbar för stopp.

### E8 — Kontrollcenter & power
- `nirupi menu` (rofi): tema, wifi, bluetooth, ljud, effekt, uppdateringar, appar.
- Power-meny: lås/suspend/reboot/shutdown.
- Bluetooth/brightness/VPN-segment.

### E9 — Cross-distro & release
- Nerd Font-provisionering (finns), paket för wallust/xss-lock/xidlehook/
  playerctl etc.
- Nya tester: statusbar, keybindings, sni, dynamic theme; utöka smoke.
- Docs (engelska) + version 0.4.0-beta.x.

## Öppna frågor
- Nextcloud-segmentet göms om inte installerat (klart enligt beslut).
- Övriga "innovativa extra" att välja bland: se listan i chatten
  (focus mode, skärmlås med blurrad wallpaper, kommandopalett, medietangenter,
  notishistorik, powerprofiler, schemalagt läge, `nirupi backup`, m.m.).
- Prioriteringsordning mellan E1–E9 när vi börjar bygga.
