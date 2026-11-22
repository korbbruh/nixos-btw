#!/usr/bin/env bash
# ~/.config/mango/waybar/indicators/ind-dnd.sh
# DND indicator. dnd.sh sets mako mode 'dnd'; match that exact string.
if makoctl mode | grep -qx 'dnd'; then
  echo '{"text": " 󰂛 ", "tooltip": "Do Not Disturb — notifications silenced", "class": "active"}'
else
  echo '{"text": ""}'
fi
