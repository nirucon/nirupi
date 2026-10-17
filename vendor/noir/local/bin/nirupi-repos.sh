#!/usr/bin/env bash
# Inspect and safely fast-forward the Git checkouts under ~/Git.
# Only fast-forward pulls are performed: dirty, diverged and detached checkouts
# are skipped with a reason. The nirupi checkout is updated through
# `nirupi update` so scripts, theme and dwm stay in sync.
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"
# Explicit repo commands work even if the status-bar segment is hidden.
export NIRUPI_GIT_FORCE=1

updates="${NIRUPI_UPDATES_BIN:-$HOME/.local/bin/nirupi-updates}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi"

die(){ printf '%s\n' "$*" >&2; exit 1; }

usage(){
  cat <<'EOF'
Usage: nirupi repos [status [--refresh] | pull (--all | NAME...)]

  status   show cached Git checkout state (--refresh fetches now)
  pull     fast-forward the selected checkouts; --all selects every repo
           with upstream changes. Dirty, diverged and detached checkouts
           are skipped. The nirupi checkout uses `nirupi update`.
EOF
}

launch_terminal(){
  local self="$HOME/.local/bin/nirupi-repos.sh" term selfq argsq run
  term="$(command -v kitty || command -v alacritty || command -v st || true)"
  [[ -n "$term" ]] || { printf 'No terminal found (kitty/alacritty/st)\n' >&2; return 1; }
  printf -v selfq '%q' "$self"
  printf -v argsq '%q ' "$@"
  run="printf 'NIRU Noir - Git repositories\n\n'; $selfq $argsq; printf '\n\nDone. Press Enter to close.'; read -r _"
  case "$(basename -- "$term")" in
    kitty)
      exec kitty --class nirupi-repos --title nirupi-repos \
        --override initial_window_width=104c --override initial_window_height=34c \
        -e bash -lc "$run" ;;
    *)
      exec "$term" --title nirupi-repos -e bash -lc "$run" ;;
  esac
}

cmd_status(){
  local force=0 count stamp="" suffix=""
  while (($#)); do
    case "$1" in
      --refresh) force=1;;
      *) die "Unknown status option: $1";;
    esac
    shift
  done
  [[ -x "$updates" ]] || die "Missing $updates"
  if (( force )); then
    "$updates" --refresh-git --force --wait >/dev/null 2>&1 || true
  else
    "$updates" --refresh-git >/dev/null 2>&1 || true
  fi
  count="$("$updates" --git-count 2>/dev/null || printf '0')"
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  [[ -r "$cache/repos.stamp" ]] && stamp="$(date -r "$cache/repos.stamp" '+%Y-%m-%d %H:%M' 2>/dev/null || true)"
  printf 'Git repositories behind: %s\n' "$count"
  [[ -n "$stamp" ]] && printf 'Last checked: %s\n' "$stamp"
  "$updates" --git-all 2>/dev/null | while IFS=$'\t' read -r name behind state ahead dirty upstream path _fetched; do
    [[ -n "${name:-}" && "$name" != '#'* ]] || continue
    (( ${behind:-0} > 0 )) || continue
    suffix=""
    (( ${dirty:-0} )) && suffix+=" · local changes"
    [[ "$state" == diverged ]] && suffix+=" · diverged"
    [[ "$state" == fetch-error ]] && suffix+=" · last known (fetch failed)"
    [[ "${upstream:-}" == "" ]] && suffix+=" · no upstream"
    printf '  %-22s %s behind%s\n' "$name" "$behind" "$suffix"
  done
  return 0
}

build_for(){
  local target="$1" conf line spec url dest build
  conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/apps.conf"
  [[ -r "$conf" && ! -L "$conf" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ "$line" == repo=* ]] || continue
    spec="${line#repo=}"
    url="${spec%%|*}"; spec="${spec#*|}"
    dest="${spec%%|*}"
    if [[ "$spec" == "$dest" ]]; then build=""; else build="${spec#*|}"; fi
    [[ -n "$dest" ]] || dest="$HOME/.local/src/$(basename "${url%.git}")"
    dest="${dest/#\~/$HOME}"
    if [[ "$dest" == "$target" ]]; then
      printf '%s' "$build"
      return 0
    fi
  done < "$conf"
}

cmd_pull(){
  local all=0 selected=0 pulled=0 skipped=0 failed=0
  local row name behind state ahead dirty upstream path _fetched build
  local -a want=() rows=()
  local w match
  local nirupi_path=""
  while (($#)); do
    case "$1" in
      --all) all=1;;
      -*) die "Unknown pull option: $1";;
      *) want+=("$1");;
    esac
    shift
  done
  (( all || ${#want[@]} > 0 )) || die 'Specify --all or at least one repository name/path'
  [[ -x "$updates" ]] || die "Missing $updates"

  # Fetch first; the pull itself is merge --ff-only, so a dirty or diverged
  # checkout can never be merged or rebased by accident.
  "$updates" --refresh-git --force --wait >/dev/null 2>&1 || true
  mapfile -t rows < <("$updates" --git-all 2>/dev/null || true)

  for row in "${rows[@]}"; do
    [[ -n "$row" ]] || continue
    IFS=$'\t' read -r name behind state ahead dirty upstream path _fetched <<<"$row"
    [[ -n "${name:-}" && "$name" != '#'* ]] || continue
    (( ${behind:-0} > 0 )) || continue
    match=$all
    if (( ! all )); then
      match=0
      for w in "${want[@]}"; do
        if [[ "$w" == "$name" || "$w" == "$path" ]]; then match=1; break; fi
      done
    fi
    (( match )) || continue
    selected=$((selected + 1))

    if [[ "$_fetched" == error ]]; then
      printf 'SKIP  %-22s fetch failed; try again later\n' "$name"
      skipped=$((skipped + 1)); continue
    fi
    if (( ${dirty:-0} )); then
      printf 'SKIP  %-22s local changes\n' "$name"
      skipped=$((skipped + 1)); continue
    fi
    if [[ -z "${upstream:-}" ]]; then
      printf 'SKIP  %-22s no upstream configured\n' "$name"
      skipped=$((skipped + 1)); continue
    fi
    if [[ "$state" == detached ]]; then
      printf 'SKIP  %-22s detached HEAD\n' "$name"
      skipped=$((skipped + 1)); continue
    fi
    if (( ${ahead:-0} > 0 )); then
      printf 'SKIP  %-22s diverged (%s local commit(s)); resolve manually\n' "$name" "$ahead"
      skipped=$((skipped + 1)); continue
    fi

    if [[ "$name" == nirupi && "$path" == "$HOME/Git/nirupi" && "${NIRUPI_REPOS_NO_SELF_UPDATE:-0}" != 1 ]]; then
      nirupi_path="$path"
      printf 'DEFER %-22s use nirupi update\n' "$name"
      continue
    fi

    if GIT_TERMINAL_PROMPT=0 git -C "$path" merge --ff-only '@{upstream}' >/dev/null 2>&1; then
      printf 'PULL  %-22s ok\n' "$name"
      pulled=$((pulled + 1))
      build="$(build_for "$path")"
      if [[ -n "$build" ]]; then
        printf 'BUILD %-22s %s\n' "$name" "$build"
        if ! ( cd "$path" && bash -lc "$build" ); then
          printf 'FAIL  %-22s build command failed\n' "$name"
          failed=$((failed + 1))
        fi
      fi
    else
      printf 'FAIL  %-22s cannot fast-forward; resolve manually\n' "$name"
      failed=$((failed + 1))
    fi
  done

  if (( selected == 0 )); then
    printf 'No selected repositories have upstream changes.\n'
  fi
  printf 'Summary: %s updated, %s skipped, %s failed.\n' "$pulled" "$skipped" "$failed"

  # Let the status bar notice that the cached state is no longer valid.
  rm -f -- "$cache/repos.stamp" "$cache/repos.attempt" "$cache/repos.count"

  if [[ -n "$nirupi_path" ]]; then
    printf '\nUpdating nirupi through nirupi update (scripts + dwm stay in sync) ...\n'
    exec env NIRUPI_REPO="$nirupi_path" "$HOME/.local/bin/nirupi" update
  fi
  (( failed == 0 ))
}

args=(); terminal=0
for a in "$@"; do
  if [[ "$a" == --terminal ]]; then terminal=1; else args+=("$a"); fi
done
if (( terminal )); then
  launch_terminal "${args[@]}"
fi
set -- "${args[@]}"

cmd="${1:-status}"
shift || :
case "$cmd" in
  status) cmd_status "$@";;
  pull) cmd_pull "$@";;
  help|-h|--help) usage;;
  *) usage >&2; exit 2;;
esac
