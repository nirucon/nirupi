#!/usr/bin/env bash
# Publish complete release source to the existing GitHub repository.
# Requires git authentication on the operator's workstation.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${NIRUPI_GITHUB_URL:-https://github.com/nirucon/nirupi.git}"
BRANCH="${NIRUPI_GITHUB_BRANCH:-main}"
[[ -f "$ROOT/VERSION" && -f "$ROOT/install.sh" ]] || { echo 'Invalid source tree' >&2; exit 1; }
command -v git >/dev/null || { echo 'git is required' >&2; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
printf 'Cloning %s (%s)\n' "$REPO_URL" "$BRANCH"
git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$work/repo"
# Preserve existing remote-only files; never overwrite Git metadata.
find "$ROOT" -mindepth 1 -maxdepth 1 ! -name .git -exec cp -a -- '{}' "$work/repo/" \;
cd "$work/repo"
git add -A
if git diff --cached --quiet; then echo 'No changes to publish'; exit 0; fi
echo 'Files to publish:'
git diff --cached --stat
printf '\nPublish all staged files to %s/%s? Type PUBLISH: ' "$REPO_URL" "$BRANCH"
read -r answer
[[ "$answer" == PUBLISH ]] || { echo 'Cancelled'; exit 1; }
git commit -m "release: NIRUPI $(cat "$ROOT/VERSION") complete source tree"
git push origin "HEAD:$BRANCH"
echo 'Complete source push succeeded.'
