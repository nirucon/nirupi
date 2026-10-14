#!/bin/bash
# Browse and copy old screenshots to the clipboard (standalone version)
# Del av DWM config by Nicklas Rudolfsson

screenshots_dir="$HOME/Pictures/Screenshots"

# Check if the folder exists (follow symlink)
if [[ ! -e "$screenshots_dir" ]]; then
  notify-send 'Screenshot Browser' 'Screenshots folder not found'
  exit 1
fi

# Choose browse method
method=$(echo -e "Browse (list)\nBrowse (visual)" |
  rofi -dmenu -i -p "Screenshot Browser:" \
    -theme-str 'window {width: 350px;} listview {lines: 2;}')

case "$method" in
"Browse (list)")
  # Find all images, sorted by date (newest first)
  # Use -L to follow symlinks
  mapfile -t images < <(find -L "$screenshots_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -printf "%T@ %p\n" 2>/dev/null | sort -rn | cut -d' ' -f2-)

  if [[ ${#images[@]} -eq 0 ]]; then
    notify-send 'Screenshot Browser' 'No screenshots found'
    exit 0
  fi

  # Build a list of relative paths
  declare -a display_list
  for img in "${images[@]}"; do
    rel_path="${img#$screenshots_dir/}"
    display_list+=("$rel_path")
  done

  # Visa i rofi
  if selected=$(printf '%s\n' "${display_list[@]}" | rofi -dmenu -i -p "Select screenshot (text search):" -format 'i' -theme-str 'window {width: 600px;} listview {lines: 15;}'); then
    selected_file="${images[$selected]}"
    xclip -selection clipboard -t image/png -i "$selected_file"
    notify-send 'Screenshot Browser' "Copied to clipboard: $(basename "$selected_file")"
  fi
  ;;

"Browse (visual)")
  # Check if there are images (follow symlinks with -L)
  if [[ -z $(find -L "$screenshots_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null) ]]; then
    notify-send 'Screenshot Browser' 'No screenshots found'
    exit 0
  fi

  # Open sxiv in thumbnail mode
  notify-send 'Screenshot Browser' 'Use arrows to navigate, Enter to copy, q to quit'

  selected=$(sxiv -t -o -r "$screenshots_dir" 2>/dev/null)

  if [[ -n "$selected" ]]; then
    xclip -selection clipboard -t image/png -i "$selected"
    notify-send 'Screenshot Browser' "Copied to clipboard: $(basename "$selected")"
  fi
  ;;

*)
  # The user cancelled
  exit 0
  ;;
esac
