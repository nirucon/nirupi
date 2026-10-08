# NIRUPI 0.2.0-alpha.11 — Engineering notes

## Changed
- Removed the fragile `RETURN` trap in the Suckless build routine; build stages are now explicitly cleaned after normal compilation and build failure.
- Added behavior-level file-operation tests for backup, unrelated symlink refusal, and directory collision.
- Fixed a literal `\\n` in the installation-plan display.
- Guarded against replacing a pre-existing symlink at `/usr/local/bin/slock`.

## Still blocking hardware-ready status
- Test complete package transactions on disposable installs of each distribution.
- Test DWM/dmenu/st/slock build against real distro development libraries.
- Verify SDDM theme QML dependencies and graphical login (both SDDM and startx).
- Audit statusbar process/caching behavior and all helper script dependencies.
- Test rollback for system-level files and service enablement.
- Publish and verify the complete source repository.

`tests/file-ops.sh` must be run as an unprivileged user. No clean installation is claimed to have passed.
