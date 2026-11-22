#!/usr/bin/env bash
# ~/.config/mango/wallpaper.sh
# Pure wallpaper switcher. No color generation — themes are handled separately
# by theme-pick.sh. This only sets the wallpaper and remembers it for boot.
#
# Usage:
#   wallpaper.sh                  # rofi thumbnail-pick from the dir
#   wallpaper.sh /path/to/img     # set a specific image
#   wallpaper.sh --random         # random image from the dir
set -euo pipefail

WALL_DIR="$HOME/Pictures/Wallpapers"
STATE="$HOME/.cache/current-wallpaper"

pick_with_rofi() {
  # Show just the basename as the label (full path is ugly + truncates), keep
  # the thumbnail pointing at the real file. Reconstruct the path after picking.
  local pick
  pick=$(
    find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) |
      sort |
      while IFS= read -r f; do
        printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
      done |
      rofi -dmenu -show-icons -p "wallpaper" -theme ~/.config/rofi/picker.rasi
  )
  [ -z "$pick" ] && return 0
  # map basename back to a full path (first match under WALL_DIR)
  find "$WALL_DIR" -type f -name "$pick" | head -1
}

pick_random() {
  find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) |
    shuf -n1
}

case "${1:-}" in
--random) IMG="$(pick_random)" ;;
"") IMG="$(pick_with_rofi)" ;;
*) IMG="$1" ;;
esac

[ -z "${IMG:-}" ] && exit 0
[ -f "$IMG" ] || {
  echo "not a file: $IMG" >&2
  exit 1
}

# set wallpaper (swaybg can't reload in place; kill + respawn)
pkill swaybg 2>/dev/null || true
swaybg -m fill -i "$IMG" >/dev/null 2>&1 &

printf '%s\n' "$IMG" >"$STATE"
cp -f "$IMG" "$HOME/.cache/current-wallpaper.jpg"
