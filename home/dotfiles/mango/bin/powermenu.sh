#!/usr/bin/env bash
# ~/.config/mango/bin/powermenu.sh

options="$(printf '\uf023  Lock\n\uf2f5  Logout\n\uf186  Suspend\n\uf021  Reboot\n\uf011  Shutdown')"
chosen="$(printf '%s\n' "$options" | rofi -dmenu -i -p "power" \
  -theme ~/.config/rofi/kev.rasi \
  -theme-str 'listview {lines: 5;} window {width: 300px;}')"

case "${chosen}" in
*Lock) swaylock -f ;;
*Logout) mmsg dispatch quit ;;
*Suspend) systemctl suspend ;;
*Reboot) systemctl reboot ;;
*Shutdown) systemctl poweroff ;;
esac
