#!/usr/bin/env bash
# NIRUPI bootstrap: clone (or update) the source checkout and hand off to
# install.sh. Run from a local text TTY for --apply.
#   curl -fsSL https://raw.githubusercontent.com/nirucon/nirupi/main/bootstrap.sh | bash -s -- --plan
set -Eeuo pipefail
REPO="${NIRUPI_REPO:-https://github.com/nirucon/nirupi.git}"
DIR="${NIRUPI_DIR:-$HOME/Git/nirupi}"
command -v git >/dev/null 2>&1 || { echo 'git is required' >&2; exit 1; }
if [[ -d "$DIR/.git" ]]; then
  echo "Updating $DIR"
  git -C "$DIR" pull --ff-only
else
  mkdir -p "$(dirname "$DIR")"
  echo "Cloning $REPO -> $DIR"
  git clone "$REPO" "$DIR"
fi
exec bash "$DIR/install.sh" "$@"
