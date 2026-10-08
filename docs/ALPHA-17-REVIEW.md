# Alpha.17 — System session collision prevention

## Fixed
- Check system-level Xsession launcher and desktop entry **before package installation**.
- Refuse unmanaged launchers, desktop entries, symlinks, and unexpected file types.
- Repeat collision checks immediately before session deployment.
- Add functional tests for valid, foreign, and symlink session files.

## Still open
- Complete GitHub source publication, clean-clone validation.
- Actual compilation of patched DWM/dmenu/st/slock on supported distributions.
- SDDM theme QML dependency verification and real graphical login.
- Full manifest and rollback for dotfiles and system-level files.
- Statusbar runtime benchmarks and all shortcut checks.

This remains a pretest alpha; do not install over a valuable desktop.
