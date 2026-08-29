#!/usr/bin/env bash
# ~/.config/mango/bin/nightlight.sh
# Toggle the wlsunset scheduler on/off. When on, wlsunset auto-warms the
# screen in the evening (3500K after 19:00) and returns to neutral (6500K)
# after 06:00. This is the normal scheduled mode -- valid high>low temps.
set -euo pipefail

if pgrep -x wlsunset >/dev/null; then
  pkill -x wlsunset
  notify-send -h string:x-canonical-private-synchronous:nightlight \
    -i display "Night Light: OFF" "Scheduler stopped"
else
  wlsunset -T 6500 -t 4000 -S 06:00 -s 19:00 >/dev/null 2>&1 &
  notify-send -h string:x-canonical-private-synchronous:nightlight \
    -i weather-clear-night "Night Light: ON" "Warm after 19:00, neutral after 06:00"
fi

# refresh the waybar nightlight indicator immediately (signal 11)
pkill -SIGRTMIN+10 waybar
