# NIRUPI

NIRUPI is a modular post-install setup for the NIRU Noir Suckless desktop on Arch, CachyOS, Debian 13 and Void Linux (glibc). It includes DWM, dmenu, st, slock, an SDDM theme and desktop helpers.

## Requirements

An X11-capable Linux installation with supported package management. NIRUPI is experimental and has not yet been validated as a complete clean desktop installation on physical hardware.

## Inspect before installing

```sh
./install.sh --plan
./install.sh --doctor
./install.sh --audit
./tests/preflight.sh
./tests/smoke.sh
```

## Installation in a disposable test environment

```sh
./install.sh --apply --session sddm
```

Alternatively use `--session startx`. Run from a local text console as a regular user. Review the proposed changes before approval. Package installation can trigger a full system upgrade and there is no complete rollback.

## Documentation

See `docs/` for testing guidance, technical audits and development notes.

## License

Original project contributions are by Ing Leif Nicklas Rudolfsson. Bundled upstream components retain their respective licenses. Review the license notices before redistribution; no blanket MIT license is claimed for third-party code.
