# NIRUPI v0.6 — execution plan (handoff)

Goal: implement sections 1–4, 6–8 from the "free vision" list, tested, deployed
to the three live machines, and remove obsolete leftovers. Keep the minimal
monochrome **Niru Noir** feel — everything opt-in/quiet, no systray/graphs.

Hosts for live verification (ask for the temp password again; do NOT store it):
`ingwaz` (Debian), `othala` (Debian), `void` (Void glibc). Repo on each at
`~/Git/nirupi`. Upgrade path that works over SSH: `git pull` +
`bash ./install.sh --update-dots`; dwm rebuild is manual (see "Deploy").

Build/verify loop per change: `bash tests/smoke.sh` (must stay green, currently
37), `bash tests/compile-suckless.sh`, `bash tests/keybindings.sh`,
`bash tests/dwm-patches.sh`. Commit small, push `main`, then deploy.

---

## R1. Bar & dwm (patches)
Hand-integrate on dwm 6.8 (`vendor/suckless/dwm/`, edit `dwm.c` + `config.h`),
compile and add tests. Beware the statuscmd click math (widths) and section ids
(must stay out of 9–13).
- **statusallmons**: draw the status bar on every monitor (today only selected,
  `dwm.c:936`). Verify statuscmd clicks on each monitor.
- **barpadding**: add `bh` padding + `vertpad`/`sidepad` config.
- **tagicons**: distinct glyph vs label (or set `tags[]` to Nerd glyphs).
- **focusurgent**: keybinding to jump to urgent window.
- **actualfullscreen**: real fullscreen instead of monocle.
- **swallow**: terminal swallows its spawned window.
- **cyclelayouts**: keybinding to cycle layouts.
- Already present: pertag, gaps (gappx), ewmhtags, movestack, rotatestack,
  scratchpad, centeredmaster.
- Add keybindings for the new functions; keep `tests/keybindings.sh` green
  (no collisions) and regenerate `docs/KEYBINDINGS.md` (R7).
- Extend `tests/dwm-patches.sh` to assert the new patches + id safety.

## R2. Theme depth
- **st + dmenu Xresources patches** (`vendor/suckless/st`, `dmenu`): read colors
  from Xresources so the dynamic theme applies live without rebuild.
  `lib/theme.sh` already writes `st.*` and `dmenu.*` into `xresources.noir` —
  verify they take effect.
- **Generate SDDM, rofi and dunst from tokens** (today static): produce
  `Black-Metal.rasi`, `dunstrc`, and the SDDM theme colors from
  `vendor/noir/theme/tokens.env` in `lib/theme.sh`.
- **Noir lock screen**: slock already blurs the current root (Imlib2). Set Noir
  colors/text in `vendor/suckless/slock/config.h`; optional `nirupi lock`
  wrapper that blurs and locks.
- **`nirupi theme list|preview`** + extra built-in palettes (Noir default,
  Noir-warm, Noir-cool) as token variants under `vendor/noir/theme/`.
- **Curated wallpaper→palette** sets; extend `nirupi theme wallpaper`/`mode`.

## R3. Session & effect
- **Idle ladder** in `runtime-session.sh` + `runtime/session.conf.example`:
  dim → lock → DPMS off → suspend, each optional (`IDLE_DIM_MINUTES`,
  `IDLE_LOCK_MINUTES`, `IDLE_DPMS_MINUTES`, `IDLE_SUSPEND_MINUTES`). Use
  xidlehook if present, else xautolock (`-locker`), else xss-lock (lock only).
- **Lock on suspend** (xss-lock/loginctl hook or session wrapper).
- **Logout confirmation**: `Super+Shift+q` opens a small rofi confirm instead of
  quitting immediately.
- **Night light** (gammastep/redshift) toggle in control center + keybinding.
- Add `gammastep`/`redshift` (best-effort) to `OPTIONAL_PKGS`.

## R4. Web apps (open in Helium)
Existing launchers live in `vendor/noir/local/bin/` (`webapp-dmenu.sh`,
`webapp-dmenu-brave.sh`, `webapp-ai-launcher.sh`, `tui-dmenu.sh`, `sr-dmenu.sh`)
and in `~/.local/bin` on the machines. Improve + standardize:
- Default to **helium** (Chromium-based, supports `--app=URL`); fall back to
  brave/chromium. Use `nirupi-browser`-style resolution.
- Add **`nirupi webapp add|list|remove NAME URL`**: create a `.desktop` entry
  (`Exec=... --app=URL --class=...`) so apps appear in dmenu/palette.
- Keep it quiet/minimal.

## R5. AI/agent — SKIP (deferred by request).

## R6. Ops & reliability
- **CI**: `.github/workflows/ci.yml` — run `tests/smoke.sh` on
  `ubuntu-latest` and in an `archlinux` container per push/PR.
- **shellcheck** step in CI (tolerate existing warnings via `--severity=error`).
- **`nirupi doctor --fix`**: provision Nerd Font + an idle-lock tool when safe.
- Keep `nirupi update` / update indicator; optional scheduled backup.

## R7. Onboarding & docs (no screenshots)
- **Generate `docs/KEYBINDINGS.md`** from `config.h` via a small
  `tools/gen-keybindings.sh`; run it in tests so it never drifts.
- **Installer TUI** (whiptail) for a few choices (session, font, optional
  packages) — optional, non-fatal if whiptail is absent.
- Update `README.md`, `docs/USAGE.md`, `CHANGELOG.md` for all of the above.

## R8. Suckless refresh
Covered by R1 (dwm patches) + R2 (st/dmenu Xresources). Optional: **tabbed** for
st tabs if it stays minimal.

---

## Leftovers to remove (cruft)
- Remove the compatibility symlink `~/.local/bin/nirupi-status-click` (no
  extension) once all machines run dwm rebuilt from the `.sh` config.
- Re-scan `vendor/noir/local/bin/` for unused scripts; remove any that are not
  in the deploy list and not referenced.
- Prune old docs (already done for ALPHA/BETA); keep ROADMAP/CHANGELOG/TESTING.
- On machines: `nirupi gc --yes --legacy` (already run once; repeat after each
  release).

## Deploy (over SSH, cannot use interactive `--apply`)
Per host: `git pull --ff-only`; `bash ./install.sh --update-dots` (scripts +
bundle + theme); rebuild dwm manually (copy existing bin dir as base, `make` the
vendor dwm, install to `<ver>/bin`, relink `dwm dmenu st dmenu_run dmenu_path
stest`); install optional packages per-package (best effort); relogin to run new
dwm. Verify with `tests/post-install-verify.sh`, `nirupi doctor`,
`nirupi status --once`, `nirupi gc --dry-run`.

## Definition of done
- `tests/smoke.sh` green (>= 40 checks) on Debian (container + real), Arch
  (container), Void (real).
- New dwm (R1) builds and runs on all three; bar correct on all monitors; no
  empty segments; clicks work.
- st/dmenu follow the theme live; SDDM/rofi/dunst generated from tokens; Noir
  lock screen.
- Idle ladder + logout confirm + night light working (per available tools).
- `nirupi webapp` opens in helium; `.desktop` entries present.
- CI green; KEYBINDINGS.md generated; README/USAGE/CHANGELOG updated.
- Leftovers removed; `nirupi gc` clean.

## Notes for the next session
- Version after this work: bump to **0.6.0**.
- Do NOT commit any credentials. Re-ask for the temp SSH password.
- Prefer many small, tested commits; deploy and verify per epic.
