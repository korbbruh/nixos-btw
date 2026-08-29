#!/usr/bin/env bash
# ~/.config/mango/waybar/indicators/ind-nightlight.sh
# Night light indicator. nightlight.sh toggles wlsunset.
if pgrep -x wlsunset >/dev/null; then
  echo '{"text": " 󰖔 ", "tooltip": "Night Light on — warm temperature", "class": "active"}'
else
  echo '{"text": ""}'
fi
