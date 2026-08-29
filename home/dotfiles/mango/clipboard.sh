#!/usr/bin/env bash
# ~/.config/mango/clipboard.sh
# Clipboard history picker. cliphist records history (started in autostart.sh),
# rofi displays it, your pick is decoded back onto the clipboard.
#   yay -S cliphist wl-clipboard
#
# Requires these watchers running (add to autostart.sh):
#   wl-paste --type text  --watch cliphist store &
#   wl-paste --type image --watch cliphist store &
set -euo pipefail

choice=$(cliphist list | rofi -dmenu -theme dmenu -p "clip") || exit 0
[ -z "$choice" ] && exit 0
printf '%s' "$choice" | cliphist decode | wl-copy
