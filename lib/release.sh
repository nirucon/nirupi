#!/usr/bin/env bash
# Release link snapshots: intentionally limited to six NIRUPI-owned binary links.
# This is NOT a rollback of packages, system session registration or user configs.
RELEASE_APPS=(dwm dmenu st dmenu_run dmenu_path stest)
release_root(){ printf '%s' "$STATE/release-snapshots"; }
release_safe_state(){
 check_home_path_safety
 local dir
 dir="$(release_root)"
 [[ ! -L $dir && ( ! -e $dir || -d $dir ) ]] || die "Unsafe snapshot directory: $dir"
}
release_snapshot(){
 local id="$1" dir app link target
 [[ $id =~ ^[0-9]{8}-[0-9]{6}-[0-9]+$ ]] || die 'Invalid snapshot ID'
 release_safe_state
 dir="$(release_root)/$id"
 [[ ! -e $dir && ! -L $dir ]] || die "Snapshot already exists: $dir"
 mkdir -m 0700 -p -- "$dir"
 : > "$dir/links.tsv"
 chmod 0600 "$dir/links.tsv"
 for app in "${RELEASE_APPS[@]}"; do
  link="$HOME/.local/bin/$app"
  if [[ -L $link ]]; then
   target="$(readlink -- "$link")"
   [[ $target == "$HOME/.local/lib/nirupi/"* ]] || die "Unmanaged link: $link"
   [[ -f $target && -x $target ]] || die "Broken release link: $link"
   printf '%s\t%s\n' "$app" "$target" >> "$dir/links.tsv"
  elif [[ -e $link ]]; then die "Unmanaged binary: $link"
  else printf '%s\t%s\n' "$app" 'ABSENT' >> "$dir/links.tsv"
  fi
 done
 printf '%s\n' "$VERSION" > "$dir/requested-version"
 log "Binary rollback snapshot: $dir"
}
release_history(){
 release_safe_state
 local dir
 dir="$(release_root)"
 [[ -d $dir ]] || { echo 'No release snapshots'; return 0; }
 find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r
}
release_rollback(){
 [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] || die 'Rollback requires a text TTY'
 [[ -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] || die 'Rollback over SSH refused'
 [[ -t 0 ]] || die 'Rollback requires an interactive terminal'
 release_safe_state
 local root dir id app target link current tmp line_count=0
 root="$(release_root)"
 [[ -d $root ]] || die 'No snapshots available'
 id="$(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r | head -n 1)"
 [[ $id =~ ^[0-9]{8}-[0-9]{6}-[0-9]+$ ]] || die 'No valid snapshot'
 dir="$root/$id"
 [[ -f $dir/links.tsv && ! -L $dir/links.tsv ]] || die 'Unsafe snapshot manifest'
 # Validate the ENTIRE manifest and current links before modifying anything.
 local -A seen=()
 while IFS=$'\t' read -r app target; do
  case " ${RELEASE_APPS[*]} " in *" $app "*) ;; *) die "Unexpected app in snapshot: $app";; esac
  [[ ! ${seen[$app]+yes} ]] || die "Duplicate snapshot entry: $app"
  seen[$app]=1; ((line_count+=1))
  if [[ $target != ABSENT ]]; then
   [[ $target == "$HOME/.local/lib/nirupi/"* && -f $target && -x $target ]] || die "Unsafe/missing rollback target: $target"
  fi
  link="$HOME/.local/bin/$app"
  if [[ -L $link ]]; then
   current="$(readlink -- "$link")"
   [[ $current == "$HOME/.local/lib/nirupi/"* ]] || die "Unmanaged current link: $link"
  elif [[ -e $link ]]; then die "Unmanaged current file: $link"
  fi
 done < "$dir/links.tsv"
 [[ $line_count == ${#RELEASE_APPS[@]} ]] || die 'Incomplete rollback manifest'
 printf 'Restore six binary links from snapshot %s? Type ROLLBACK: ' "$id"
 local confirm; read -r confirm
 [[ $confirm == ROLLBACK ]] || die 'Cancelled'
 while IFS=$'\t' read -r app target; do
  link="$HOME/.local/bin/$app"
  if [[ $target == ABSENT ]]; then rm -f -- "$link"; continue; fi
  tmp="$(mktemp "$HOME/.local/bin/.nirupi-rollback.XXXXXXXX")"
  rm -f -- "$tmp"
  ln -s -- "$target" "$tmp"
  mv -f -- "$tmp" "$link"
 done < "$dir/links.tsv"
 log "Restored binary links from $id. User configs, SDDM and packages were NOT rolled back."
}
