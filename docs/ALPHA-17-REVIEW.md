# NIRUPI alpha.17 — X11 session preflight

## Fixed
- Added `check_system_session_conflicts` to `lib/install.sh`.
- Runs before package installation and again immediately before Xsession registration.
- Rejects a foreign global launcher, foreign desktop entry, symlink and non-regular session files.
- Added `tests/system-session.sh` with functional cases for safe and conflicting sessions.

## Verified
- Bash syntax and existing smoke checks.
- Functional Xsession conflict regression tests.
- ZIP integrity.

## Remaining roadmap
- Complete GitHub source-tree publication and clean-clone validation.
- Real Suckless compilation and SDDM/startx login on target distros.
- Full manifest/rollback, package resolution, statusbar profiling, shortcuts and visual polish.

**Not a production installation candidate.**
