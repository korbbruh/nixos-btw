#!/usr/bin/env bash
# ~/.config/mango/waybar/indicators/ind-caffeine.sh
# Caffeine state = whether the swayidle user unit is running.
if systemctl --user is-active --quiet swayidle; then
  echo '{"text": ""}'
else
  echo '{"text": " 󰅶 ", "tooltip": "Caffeine on — idle & lock disabled", "class": "active"}'
fi
