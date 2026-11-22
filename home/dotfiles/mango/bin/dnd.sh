#!/usr/bin/env bash
# ~/.config/mango/bin/dnd.sh
# Toggle Do Not Disturb via mako's mode system. In 'dnd' mode, notifications
# are suppressed (mako still records them; they just don't pop).
#
# Requires this block in ~/.config/mako/config:
#   [mode=dnd]
#   invisible=1
set -euo pipefail

if makoctl mode | grep -qx dnd; then
  makoctl mode -r dnd
  notify-send -h string:x-canonical-private-synchronous:dnd \
    -i notification "DND: OFF" "Notifications back on"
else
  sleep 0.4
  makoctl mode -a dnd
  notify-send -h string:x-canonical-private-synchronous:dnd \
    -i notification-disabled "DND: ON" "Notifications silenced"
fi

# refresh the waybar DND indicator immediately (signal 10)
pkill -SIGRTMIN+8 waybar
