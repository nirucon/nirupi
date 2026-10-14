#!/bin/bash
# Screenshot with select + optional save with subfolders + rename + browse old screenshots
# Del av DWM config by Nicklas Rudolfsson

# Take a screenshot to a temp file
tmp=$(mktemp "${TMPDIR:-/tmp}/nirupi-shot-XXXXXXXX.png") || exit 1
trap 'rm -f -- "$tmp"' EXIT
for cmd in maim xclip rofi; do
  command -v "$cmd" >/dev/null 2>&1 || { printf 'Screenshot: missing %s\n' "$cmd" >&2; exit 127; }
done
maim -s "$tmp" || exit 1

# Copy to clipboard first (always happens)
xclip -selection clipboard -t image/png -i "$tmp"

# First choice: where do you want to save?
choice=$(echo -e "No\nSave to /Screenshots\nSave to /Screenshots/Important\nSave to /Screenshots/Fun\nSave & edit in Gimp\nSave & view in sxiv\nBrowse old (list)\nBrowse old (visual)" |
  rofi -dmenu -i -p "Save screenshot?" \
    -theme-str 'window {width: 400px;} listview {lines: 8;}')

# Function to save with an optional rename
save_with_rename() {
  local target_dir="$1"
  local timestamp=$(date +%F_%H-%M-%S)

  # Ask whether the user wants to rename
  rename_choice=$(echo -e "No\nYes" |
    rofi -dmenu -i -p "Rename file before saving?" \
      -theme-str 'window {width: 350px;} listview {lines: 2;}')

  if [[ "$rename_choice" == "Yes" ]]; then
    # Let the user type a custom name
    custom_name=$(rofi -dmenu -p "Enter filename (without .png):" \
      -theme-str 'window {width: 400px;}' </dev/null)

    if [[ -n "$custom_name" ]]; then
      # Strip .png if the user typed it
      custom_name="${custom_name%.png}"
      # Prevent traversal, separators, control chars and hidden dot-only names.
      custom_name="$(printf '%s' "$custom_name" | tr -cd '[:alnum:] _.-' | sed 's#\.\.##g; s#^[. ]*##; s#[. ]*$##')"
      [[ -n "$custom_name" ]] || custom_name="screenshot"
      file="$target_dir/${custom_name}_${timestamp}.png"
    else
      # If the user typed nothing, just use the timestamp
      file="$target_dir/${timestamp}.png"
    fi
  else
    # Standard: bara timestamp
    file="$target_dir/${timestamp}.png"
  fi

  mkdir -p "$target_dir"
  mv "$tmp" "$file"
  echo "$file"
}

# Function to browse old screenshots with rofi (text list)
browse_old_screenshots_rofi() {
  local screenshots_dir="$HOME/Pictures/Screenshots"

  # Check if the folder exists (follow symlink with cd)
  if [[ ! -e "$screenshots_dir" ]]; then
    notify-send 'Screenshot Browser' 'Screenshots folder not found'
    rm -f "$tmp"
    exit 0
  fi

  # Find all images, sorted by date (newest first)
  # Use -L to follow symlinks
  mapfile -t images < <(find -L "$screenshots_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -printf "%T@ %p\n" 2>/dev/null | sort -rn | cut -d' ' -f2-)

  if [[ ${#images[@]} -eq 0 ]]; then
    notify-send 'Screenshot Browser' 'No screenshots found'
    rm -f "$tmp"
    exit 0
  fi

  # Build a list of relative paths for readability
  declare -a display_list
  for img in "${images[@]}"; do
    rel_path="${img#$screenshots_dir/}"
    display_list+=("$rel_path")
  done

  # Visa i rofi
  selected_index=-1
  for i in "${!display_list[@]}"; do
    if selected=$(printf '%s\n' "${display_list[@]}" | rofi -dmenu -i -p "Select screenshot (text search):" -format 'i' -theme-str 'window {width: 600px;} listview {lines: 15;}'); then
      selected_index=$selected
      break
    else
      # The user pressed Escape
      rm -f "$tmp"
      exit 0
    fi
  done

  # If something was selected
  if [[ $selected_index -ge 0 ]]; then
    selected_file="${images[$selected_index]}"
    xclip -selection clipboard -t image/png -i "$selected_file"
    notify-send 'Screenshot Browser' "Copied to clipboard: $(basename "$selected_file")"
  fi

  # Remove the new screenshot (we browsed instead)
  rm -f "$tmp"
}

# Function to browse old screenshots with sxiv (visual thumbnails)
browse_old_screenshots_sxiv() {
  local screenshots_dir="$HOME/Pictures/Screenshots"

  # Check if the folder exists (follow symlink)
  if [[ ! -e "$screenshots_dir" ]]; then
    notify-send 'Screenshot Browser' 'Screenshots folder not found'
    rm -f "$tmp"
    exit 0
  fi

  # Check if there are images (follow symlinks with -L)
  if [[ -z $(find -L "$screenshots_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null) ]]; then
    notify-send 'Screenshot Browser' 'No screenshots found'
    rm -f "$tmp"
    exit 0
  fi

  # Open sxiv to browse (recursive, includes subfolders)
  # -r = rekursiv, -t = thumbnail mode, -o = output selected file
  notify-send 'Screenshot Browser' 'Use arrows to navigate, Enter to copy, q to quit'

  selected=$(sxiv -t -o -r "$screenshots_dir" 2>/dev/null)

  if [[ -n "$selected" ]]; then
    # Copy the selected image to the clipboard
    xclip -selection clipboard -t image/png -i "$selected"
    notify-send 'Screenshot Browser' "Copied to clipboard: $(basename "$selected")"
  fi

  # Remove the new screenshot (we browsed instead)
  rm -f "$tmp"
}

case "$choice" in
"No")
  # Remove the temp file
  rm -f "$tmp"
  notify-send 'Screenshot' 'Copied to clipboard (not saved)'
  ;;

"Save to /Screenshots")
  dir="$HOME/Pictures/Screenshots"
  file=$(save_with_rename "$dir")
  notify-send 'Screenshot' "Saved to Screenshots: $(basename "$file")"
  ;;

"Save to /Screenshots/Important")
  dir="$HOME/Pictures/Screenshots/Important"
  file=$(save_with_rename "$dir")
  notify-send 'Screenshot' "Saved to Important: $(basename "$file")"
  ;;

"Save to /Screenshots/Fun")
  dir="$HOME/Pictures/Screenshots/Fun"
  file=$(save_with_rename "$dir")
  notify-send 'Screenshot' "Saved to Fun: $(basename "$file")"
  ;;

"Save & edit in Gimp")
  dir="$HOME/Pictures/Screenshots"
  mkdir -p "$dir"
  file="$dir/$(date +%F_%H-%M-%S).png"
  mv "$tmp" "$file"
  notify-send 'Screenshot' "Saved & opening in Gimp: $(basename "$file")"
  gimp "$file" &
  ;;

"Save & view in sxiv")
  dir="$HOME/Pictures/Screenshots"
  mkdir -p "$dir"
  file="$dir/$(date +%F_%H-%M-%S).png"
  mv "$tmp" "$file"
  notify-send 'Screenshot' "Saved & opening in sxiv: $(basename "$file")"
  sxiv "$file" &
  ;;

"Browse old (list)")
  browse_old_screenshots_rofi
  ;;

"Browse old (visual)")
  browse_old_screenshots_sxiv
  ;;

*)
  # If the user closes the dialog or presses Escape
  rm -f "$tmp"
  ;;
esac
