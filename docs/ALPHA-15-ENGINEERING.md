# NIRUPI alpha.15 — Build and session safety

## Implemented

- Validate **all** Suckless binaries and dmenu helper outputs before the first binary is installed.
- Reject a conflicting, unmanaged global NIRUPI Xsession launcher rather than registering a desktop entry that points to it.
- Add a regression guard for these checks.

## Remaining risks

- Package names and build dependencies have not been validated on every target distribution.
- This is not a transaction: package installation, user config, SDDM, and privileged slock changes cannot yet be rolled back atomically.
- Build-output tests are structural; they do not compile all four patched projects on the target distributions.
- The full GitHub tree still requires verified publication and a clean-clone test.
