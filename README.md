# NIRUPI — NIRU Post Install

Personal NIRU Noir / patched Suckless DWM desktop installer targeting Arch, CachyOS, Debian 13 and Void Linux (glibc).

**Latest complete development archive: 0.2.0-alpha.19 — PRETEST ONLY.**

> **Publication status:** GitHub contains the audit documentation and selected tests, **not the full 138-file source release**. A clean clone is not yet installable. The complete ZIP is provided in the development conversation.

## Alpha.14 desktop integration

- Fixed a case-sensitive mismatch in wallpaper directory defaults (`~/Pictures/Wallpapers`).
- Unified `WALLPAPER_DIR` handling in the X11 session and wallpaper daemon.
- Added a per-display nonblocking `flock` to the DWM statusbar to avoid duplicate writers.
- Avoided blank kernel/host/weather/date/time bar segments.
- Added integration checks and desktop audit documentation.

See [alpha.14 audit](docs/ALPHA-14-DESKTOP-AUDIT.md).

## Planned validation

1. Resolve package dependencies and compile patched DWM/dmenu/st/slock on each target distribution.
2. Verify SDDM theme, startx, monitor layout, statusbar, shortcuts, clipboard, screenshots and suspend on actual X11.
3. Implement and test a managed-file upgrade/rollback path.
4. Publish the complete source and verify a clean clone.
5. Perform a controlled test-laptop installation.

## Full-source publication

The alpha.14 ZIP contains `publish-github.sh`. On a machine with GitHub write credentials, extract the release and run:

```sh
./publish-github.sh
```

The script clones the existing `main`, copies the complete source without replacing Git metadata, displays a change summary, requires typing `PUBLISH`, commits and pushes without force. This has **not yet been run successfully**, because the build container cannot resolve github.com.

Do not run `--apply` on a valuable workstation until target-system testing is complete.

## Alpha.15 safety checkpoint

- Validate all Suckless binary outputs and dmenu helpers before deploying any compiled binaries.
- Reject unmanaged global NIRUPI session launcher collisions.
- Add `tests/build-output.sh` and [engineering notes](docs/ALPHA-15-ENGINEERING.md).

**GitHub publication status:** the complete 140-file source tree is **not yet published**. The full release is available as a ZIP in the development conversation. A clean clone is not installable yet.

## Alpha.16 desktop and upgrade-safety checkpoint

- Validate DISPLAY and the DWM executable before launching daemons.
- Record SHA-256 checksums of NIRUPI-managed helper scripts and preserve user-modified or untracked scripts.
- Added [engineering review](docs/ALPHA-16-REVIEW.md), [session test](tests/session-runtime.sh), and `runtime-session.sh`.

**Publication warning:** Only selected source files and documentation have been pushed. The **complete 142-file alpha.16 tree is not yet on GitHub**, so cloning this repository does not produce an installable release. Use the ZIP in the development conversation. A full-tree push and clean-clone verification are still required.

## Alpha.17 X11 preflight

- Added early detection of conflicting system session files before installing packages.
- Added functional checks for unmanaged launchers and desktop entries.
- See [alpha.17 review](docs/ALPHA-17-REVIEW.md) and [test](tests/system-session.sh).

**Full-tree GitHub publication is still outstanding.** The complete alpha.17 source is delivered as a ZIP in the development conversation; this repository is not yet a verified install source.

## Alpha.18 — NIRU Noir visual consistency

- Matched DWM, st, Kitty, Alacritty and Dunst core background/foreground.
- Fixed Alacritty font size 5.5 → 11.0.
- Unified semantic 16-color ANSI palettes in st, Kitty and Alacritty.
- Standardized dmenu font family and toned down Dunst borders.
- Added [design tokens](docs/NIRU-NOIR-DESIGN.md) and [palette consistency test](tests/noir-consistency.sh).

**Source publication warning:** This repository still does **not** contain the complete alpha.18 installer source tree. The full 146-file ZIP is in the development conversation. Do not attempt a clean-clone installation yet.

## Alpha.19 — Rofi and font diagnostics

- Installer now deploys the bundled `Black-Metal.rasi` theme if absent, before Rofi config, preserving user themes.
- `--doctor` reports the actual fontconfig match for JetBrainsMono Nerd Font.
- New [Rofi integration audit](docs/ALPHA-19-REVIEW.md) and [test](tests/rofi-integration.sh).

**Important:** The full alpha.19 source tree (148 files) has **not** been pushed to this repository. The complete ZIP is supplied in the development conversation; a clean GitHub clone remains non-installable. Full source publication and clean-clone validation remain roadmap blockers.
