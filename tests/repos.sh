#!/usr/bin/env bash
# Isolated Git checkout tests: cache, safe pull rules and cross-distro helper
# syntax. No network, sudo or graphical session required.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT

export HOME="$WORK/home" XDG_CONFIG_HOME="$WORK/home/.config" XDG_CACHE_HOME="$WORK/cache"
export GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_SYSTEM=/dev/null
mkdir -p "$HOME/Git" "$XDG_CONFIG_HOME/nirupi" "$WORK/remotes"
git config --global user.name 'NIRUPI Test'
git config --global user.email 'test@example.invalid'
git config --global init.defaultBranch main

cat > "$XDG_CONFIG_HOME/nirupi/status.conf" <<EOF
SHOW_GIT_UPDATES=1
GIT_UPDATES_DIRS=("\$HOME/Git")
GIT_UPDATES_IGNORE=()
GIT_UPDATES_CACHE_SECONDS=0
EOF

UPDATES="$ROOT/runtime/nirupi-updates"
REPOS="$ROOT/vendor/noir/local/bin/nirupi-repos.sh"
CACHE="$XDG_CACHE_HOME/nirupi"

make_remote(){
  local name="$1"
  git init --bare "$WORK/remotes/$name.git" >/dev/null 2>&1
  git clone "$WORK/remotes/$name.git" "$WORK/seed-$name" >/dev/null 2>&1
  (
    cd "$WORK/seed-$name"
    printf 'one\n' > file
    git add file
    git commit -q -m one
    git push -q origin main
  )
}

advance_remote(){
  local name="$1"
  (
    cd "$WORK/seed-$name"
    printf 'two\n' >> file
    git add file
    git commit -q -m two
    git push -q origin main
  )
}

clone_repo(){
  local name="$1"
  git clone "$WORK/remotes/$name.git" "$HOME/Git/$name" >/dev/null 2>&1
}

make_remote clean;   clone_repo clean;   advance_remote clean
make_remote dirty;   clone_repo dirty;   advance_remote dirty
make_remote diverged; clone_repo diverged; advance_remote diverged
make_remote shallow; git clone --depth 1 "$WORK/remotes/shallow.git" "$HOME/Git/shallow" >/dev/null 2>&1; advance_remote shallow

# Local modifications and a diverged local commit must both be visible.
printf 'local change\n' >> "$HOME/Git/dirty/file"
(
  cd "$HOME/Git/diverged"
  printf 'local\n' > local.txt
  git add local.txt
  git commit -q -m local
)

# No upstream configured.
(
  cd "$HOME/Git"
  git init localonly >/dev/null 2>&1
  cd localonly
  printf 'x\n' > file
  git add file
  git commit -q -m initial
)

# Unreachable remote: the scan must report an error without crashing.
make_remote broken; clone_repo broken
git -C "$HOME/Git/broken" remote set-url origin "$WORK/does-not-exist.git"

bash -n "$UPDATES" "$REPOS"
count="$("$UPDATES" --refresh-git --force --wait)"
[[ "$count" == 4 ]] || { echo "FAIL: expected 4 behind repos, got $count" >&2; exit 1; }

all="$("$UPDATES" --git-all)"
field(){ printf '%s\n' "$all" | awk -F'\t' -v n="$1" -v f="$2" '$1==n {print $f}'; }
[[ "$(field clean 3)" == behind ]] || { echo 'FAIL: clean repo not behind' >&2; exit 1; }
[[ "$(field dirty 3)" == dirty ]] || { echo 'FAIL: dirty repo not detected' >&2; exit 1; }
[[ "$(field diverged 3)" == diverged ]] || { echo 'FAIL: diverged repo not detected' >&2; exit 1; }
[[ "$(field shallow 3)" == behind ]] || { echo 'FAIL: shallow repo not behind' >&2; exit 1; }
[[ "$(field localonly 3)" == no-upstream ]] || { echo 'FAIL: local-only repo not detected' >&2; exit 1; }
[[ "$(field broken 3)" == fetch-error ]] || { echo 'FAIL: fetch error not detected' >&2; exit 1; }

# The status bar reads the cached count without fetching in its render loop.
mkdir -p "$HOME/.local/bin"
ln -sf "$UPDATES" "$HOME/.local/bin/nirupi-updates"
cat > "$HOME/.local/bin/checkupdates" <<'EOF'
#!/bin/sh
exit 0
EOF
cat > "$HOME/.local/bin/xsetroot" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$WORK/bar.txt"
EOF
chmod +x "$HOME/.local/bin/checkupdates" "$HOME/.local/bin/xsetroot"
cat > "$XDG_CONFIG_HOME/nirupi/status.conf" <<EOF
SHOW_UPDATES=1
SHOW_GIT_UPDATES=1
GIT_UPDATES_DIRS=("\$HOME/Git")
GIT_UPDATES_IGNORE=()
GIT_UPDATES_CACHE_SECONDS=3600
SHOW_WEATHER=0
SHOW_NETWORK=0
SHOW_MEDIA=0
SHOW_NOW_PLAYING=0
SHOW_NEXTCLOUD=0
SHOW_BATTERY=0
SHOW_TEMP=0
SHOW_DND=0
SHOW_RECORDING=0
SHOW_CAFFEINE=0
SHOW_VOLUME=0
SHOW_MIC=0
SHOW_KERNEL=0
SHOW_HOST=0
SHOW_DATE=0
SHOW_TIME=0
EOF
timeout 8 bash "$ROOT/vendor/noir/local/bin/dwm-status.sh" >/dev/null 2>&1 || true
digits="$(tail -n1 "$WORK/bar.txt" 2>/dev/null | tr -dc '0-9')"
[[ "$digits" == *4* ]] || { cat "$WORK/bar.txt" >&2 2>/dev/null || true; echo 'FAIL: bar did not show the Git count' >&2; exit 1; }

# Pull --all: only the clean and shallow checkouts may move.
NIRUPI_REPOS_NO_SELF_UPDATE=1 NIRUPI_UPDATES_BIN="$UPDATES" \
  "$REPOS" pull --all > "$WORK/pull.log" 2>&1 || { cat "$WORK/pull.log" >&2; exit 1; }
grep -q 'PULL  clean' "$WORK/pull.log" || { cat "$WORK/pull.log" >&2; echo 'FAIL: clean not pulled' >&2; exit 1; }
grep -q 'SKIP  dirty' "$WORK/pull.log" || { cat "$WORK/pull.log" >&2; echo 'FAIL: dirty not skipped' >&2; exit 1; }
grep -q 'SKIP  diverged' "$WORK/pull.log" || { cat "$WORK/pull.log" >&2; echo 'FAIL: diverged not skipped' >&2; exit 1; }
[[ "$(git -C "$HOME/Git/clean" rev-parse HEAD)" == "$(git -C "$WORK/seed-clean" rev-parse HEAD)" ]] \
  || { echo 'FAIL: clean checkout was not fast-forwarded' >&2; exit 1; }
[[ "$(git -C "$HOME/Git/shallow" rev-parse HEAD)" == "$(git -C "$WORK/seed-shallow" rev-parse HEAD)" ]] \
  || { echo 'FAIL: shallow checkout was not fast-forwarded' >&2; exit 1; }
[[ "$(git -C "$HOME/Git/dirty" rev-parse HEAD)" != "$(git -C "$WORK/seed-dirty" rev-parse HEAD)" ]] \
  || { echo 'FAIL: dirty checkout was overwritten' >&2; exit 1; }
[[ "$(git -C "$HOME/Git/diverged" rev-parse HEAD)" != "$(git -C "$WORK/seed-diverged" rev-parse HEAD)" ]] \
  || { echo 'FAIL: diverged checkout was overwritten' >&2; exit 1; }

# Pull invalidates the bar cache; a rescan leaves only the unmergeable repos.
[[ ! -e "$CACHE/repos.stamp" && ! -e "$CACHE/repos.count" ]]
count="$("$UPDATES" --refresh-git --force --wait)"
[[ "$count" == 2 ]] || { echo "FAIL: expected dirty+diverged after pull, got $count" >&2; exit 1; }

# --refresh also drops the cached Git state.
"$UPDATES" --refresh >/dev/null
[[ ! -e "$CACHE/repos.count" && ! -e "$CACHE/repos.stamp" && ! -e "$CACHE/repos.tsv" ]]

echo 'PASS: Git update cache, safe fast-forward rules and refresh'
