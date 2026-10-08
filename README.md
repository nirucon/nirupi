# NIRUPI — NIRU Post Install

**Version:** 0.2.0-beta.1 (development / pretest)

Modular post-install prototype for the original NIRU Noir Suckless desktop on Arch, CachyOS, Debian 13 and Void Linux glibc. The original DWM, dmenu, st, slock, SDDM theme and helper scripts are bundled. The NIRU applications are not bundled.

**Not verified on physical hardware or in a complete clean X11 installation.** Review `docs/ALPHA-8-AUDIT.md` before applying.

## Read-only checks

```sh
./install.sh --plan
./install.sh --doctor
./install.sh --audit
./tests/preflight.sh
./tests/smoke.sh
```

## Disposable test machine only

```sh
./install.sh --apply --session sddm
# Or: ./install.sh --apply --session startx
```

Run from a local text TTY as a normal user. The installer prompts before changes, preserves existing per-file configuration, and requires separate consent for SDDM and privileged slock. Arch/CachyOS package installation performs an **explicitly approved full system upgrade**, not a partial upgrade. There is no complete system rollback. Read `docs/FIRST-VM-TEST.md` and `docs/ALPHA-8-AUDIT.md`.

## License and attribution

Bundled third-party sources remain subject to their own licenses. Review upstream license files before redistributing.

## Alpha.9 notes

The update adapter now emits a numeric result even when package queries fail, and update-count regression tests use mocked command output. The desktop session emits a clear diagnostic if DWM is missing. No clean install or graphical login has been validated.

See `docs/ALPHA-10-ROADMAP.md` for current changes and validation limits.

Latest engineering audit: `docs/ALPHA-12-ENGINEERING.md`.

See `docs/ALPHA-13-DWM-AUDIT.md` for the DWM integration audit and remaining blockers.

See `docs/ALPHA-14-DESKTOP-AUDIT.md` for wallpaper/statusbar fixes and outstanding validation.

## Publishing the full tree

The complete release is currently provided as a ZIP. From an extracted release
on a workstation with GitHub authentication, run `./publish-github.sh`.
It clones `main`, copies the complete release (without `.git`), stages changes,
shows the diff summary and requires typing `PUBLISH` before committing and
pushing. It does not force-push or delete remote-only files.

See `docs/ALPHA-15-ENGINEERING.md` for build and session safety changes.

Alpha.16 engineering review: `docs/ALPHA-16-REVIEW.md`.

Alpha.17: pre-package system session collision checks and functional regression tests. See `docs/ALPHA-17-REVIEW.md`.

Alpha.18: unified NIRU Noir typography and semantic terminal colors; see `docs/NIRU-NOIR-DESIGN.md`.

Alpha.19 fixes Rofi theme deployment and adds fontconfig diagnostics; see `docs/ALPHA-19-REVIEW.md`.

Alpha.20: DWM shortcut dependency checks and safer screenshot temporary files; see `docs/ALPHA-20-REVIEW.md`.

Alpha.21: DWM config and user session launcher preservation; see `docs/ALPHA-21-REVIEW.md`.

## Alpha.22 — managed upgrades

Added `lib/managed.sh` and functional managed-helper upgrade tests, including protection of user edits and recovery of executable permissions. See `docs/ALPHA-22-ENGINEERING.md`.

## Alpha.23 managed configuration upgrades

DWM config, Rofi theme, app dotfiles, Xresources and user session launchers now use a SHA-256 manifest. Existing untracked files remain untouched; only known unchanged managed files upgrade automatically. See `docs/ALPHA-23-ENGINEERING.md`.

Alpha.24: DWM builds from an existing user `config.h` when available, rather than silently ignoring personal shortcuts/layouts. See `docs/ALPHA-24-ENGINEERING.md`.

Alpha.25: early read-only preflight for unmanaged binaries, DWM config and unsafe manifests before package installation. See `docs/ALPHA-25-ENGINEERING.md`.

## Alpha.30 readiness

Read [release readiness](docs/ALPHA-30-RELEASE-READINESS.md) and [physical pilot checklist](docs/PHYSICAL-PILOT-CHECKLIST.md). New checks cover home/state symlink safety, display-manager conflicts and real non-installing Suckless build validation. This release has **not** passed a real Debian 13 VM or graphical installation. GitHub full-tree publication is still outstanding.

## Alpha.31: controlled migration from an existing DWM desktop

Use `bash ./migrate-desktop.sh --plan` to inspect exactly which *user-level desktop files* would be archived. `--apply` requires a local text TTY and explicit `REPLACE DESKTOP` confirmation. The migration makes a complete copy of selected existing files before clearing their paths, and records a rollback ID. Run `bash ./migrate-desktop.sh --rollback RUN_ID` to restore backed-up user files. **Rollback does not undo packages, system-level SDDM changes, or new files created by the subsequent installation.**

This is a separate migration, not an automatic part of `install.sh --apply`. The migration deliberately excludes Fish, SSH, Git, GPG, personal files, system packages and other display managers. For a real bare-metal pilot, test on a disposable Debian 13 machine from a TTY with a recoverable backup. **Not production-ready or fully tested in a graphical VM.**

## Bare-metal readiness

See [docs/BARE-METAL-DEPLOYMENT.md](docs/BARE-METAL-DEPLOYMENT.md). Use `bash tests/bare-metal-readiness.sh` for a read-only host report and `bash tests/post-install-verify.sh` after installation. Real Debian 13 graphical acceptance remains pending.

## Beta upgrade and verification

See [docs/BETA-1-UPGRADE.md](docs/BETA-1-UPGRADE.md) for alpha.32 → beta.1, `--verify`, release snapshots and limited binary-link rollback. Physical beta verification is still pending.
