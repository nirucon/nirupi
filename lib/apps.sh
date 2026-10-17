#!/usr/bin/env bash
# Optional user app configuration.
# Reads an optional "custom_apps.conf" and appends extra packages per distro
# and/or clones/builds external Git repositories. When the file is absent the
# installer keeps running non-interactively with the default package set.
#
# File format (comments start with '#', one directive per line):
#   package=htop                         # extra package on every distro
#   package-debian=foo bar               # extra packages on Debian
#   package-arch=baz
#   package-void=qux
#   repo=URL|DESTINATION|BUILD COMMAND   # destination and build command optional
# Sourced after lib/common.sh.

# Default Git repositories cloned to ~/Git on every clean install and update.
# Format: URL|DESTINATION|BUILD COMMAND (build optional).
DEFAULT_REPOS=(
  "https://github.com/nirucon/nirupresence.git|$HOME/Git/nirupresence|"
  "https://github.com/nirucon/nirunote.git|$HOME/Git/nirunote|"
  "https://github.com/nirucon/nplay.git|$HOME/Git/nplay|"
)

# Clone a repository on first sight, otherwise fast-forward it. Best effort.
clone_or_update_repo(){
  local url="$1" dest="${2:-}" build="${3:-}"
  [[ -n $dest ]] || dest="$HOME/Git/$(basename "${url%.git}")"
  dest="${dest/#\~/$HOME}"
  [[ $url =~ ^https:// || $url =~ ^git@ ]] || { warn "Refusing non-HTTPS/SSH repo URL: $url"; return 0; }
  [[ -e $dest && ! -d $dest ]] && { warn "Refusing non-directory repo destination: $dest"; return 0; }
  if [[ -d $dest/.git ]]; then
    log "Updating repository: $dest"
    git -C "$dest" pull --ff-only || warn "git pull failed for $dest"
  else
    log "Cloning $url -> $dest"
    mkdir -p "$(dirname "$dest")"
    git clone --depth 1 -- "$url" "$dest" || { warn "git clone failed: $url"; return 0; }
  fi
  if [[ -n $build ]]; then
    log "Building $dest: $build"
    ( cd "$dest" && bash -lc "$build" ) || warn "Build command failed in $dest"
  fi
}

# Always provision the personal default repositories (nirupresence/nirunote/nplay).
install_default_repos(){
  (( ${#DEFAULT_REPOS[@]} )) || return 0
  log "Ensuring default repositories in ~/Git (${#DEFAULT_REPOS[@]})"
  local spec url dest build
  for spec in "${DEFAULT_REPOS[@]}"; do
    url="${spec%%|*}"; spec="${spec#*|}"
    dest="${spec%%|*}"
    if [[ $spec == "$dest" ]]; then build=''; else build="${spec#*|}"; fi
    clone_or_update_repo "$url" "$dest" "$build"
  done
}

apps_conf_path(){
  local candidate
  for candidate in \
    "${NIRUPI_APPS_CONF:-}" \
    "$HOME/.config/nirupi/apps.conf" \
    "$ROOT/custom_apps.conf"; do
    [[ -n $candidate && -f $candidate && ! -L $candidate ]] && { printf '%s' "$candidate"; return 0; }
  done
  return 1
}

_pkg_token_valid(){ [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9._+:-]*$ ]]; }

load_custom_packages(){
  local conf; conf="$(apps_conf_path)" || return 0
  local line key value distro_key
  distro_key="package-${DISTRO}"
  local added=0
  while IFS= read -r line || [[ -n $line ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -n $line ]] || continue
    [[ $line == *=* ]] || { warn "Ignoring malformed line in $conf: $line"; continue; }
    key="${line%%=*}"; value="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    case "$key" in
      package|"$distro_key") ;;
      package-*) continue;;
      repo) continue;;
      *) warn "Unknown directive '$key' in $conf"; continue;;
    esac
    local token
    for token in $value; do
      _pkg_token_valid "$token" || { warn "Invalid package name '$token' in $conf"; continue; }
      if [[ " ${PKGS[*]} " != *" $token "* ]]; then PKGS+=("$token"); added=$((added+1)); fi
    done
  done < "$conf"
  (( added )) && log "custom_apps.conf: added $added package(s) for $DISTRO"
}

# Install extra packages through the native package manager.
install_custom_packages(){
  local conf; conf="$(apps_conf_path)" || return 0
  local before="${#PKGS[@]}"
  local -a base=("${PKGS[@]}")
  load_custom_packages
  ((${#PKGS[@]} > before)) || { PKGS=("${base[@]}"); return 0; }
  local -a extra=("${PKGS[@]:$before}")
  log "Installing ${#extra[@]} custom package(s): ${extra[*]}"
  case "$DISTRO" in
    arch|cachyos) sudo pacman -S --needed --noconfirm -- "${extra[@]}";;
    debian) sudo apt-get install -- "${extra[@]}";;
    void) sudo xbps-install -S -y -- "${extra[@]}";;
  esac
}

# Clone and optionally build external Git repositories listed in apps.conf.
install_custom_repos(){
  local conf; conf="$(apps_conf_path)" || return 0
  local line spec url dest build
  while IFS= read -r line || [[ -n $line ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -n $line ]] || continue
    [[ $line == repo=* ]] || continue
    spec="${line#repo=}"
    url="${spec%%|*}"; spec="${spec#*|}"
    dest="${spec%%|*}"
    if [[ $spec == "$dest" ]]; then build=''; else build="${spec#*|}"; fi
    [[ -n $dest ]] || dest="$HOME/.local/src/$(basename "${url%.git}")"
    clone_or_update_repo "$url" "$dest" "$build"
  done < "$conf"
}

custom_apps_status(){
  local conf; conf="$(apps_conf_path)" || { printf 'custom_apps.conf: not present (default packages only)\n'; return 0; }
  printf 'custom_apps.conf: %s\n' "$conf"
  local line
  while IFS= read -r line || [[ -n $line ]]; do
    [[ $line == package=* || $line == package-* || $line == repo=* ]] && printf '  %s\n' "$line"
  done < "$conf"
}

nirupi_apps(){
  local sub="${1:-status}"; shift || :
  case "$sub" in
    status) custom_apps_status;;
    list) custom_apps_status;;
    *) die 'Usage: nirupi apps [status]';;
  esac
}
