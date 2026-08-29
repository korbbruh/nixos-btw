#!/usr/bin/env bash
# ~/.config/mango/bin/caffeine.sh
# Toggle "caffeine" (keep awake) by stopping/starting the swayidle user unit.
# When caffeine is ON, swayidle is stopped, so no auto-lock, no panel-off,
# no suspend.
#
# Must go through systemctl: swayidle has Restart=always, so pkill just makes
# systemd bring it straight back.
#
# Note: sway-audio-idle-inhibit already inhibits while audio plays, so this is
# mainly for silent stuff (reading, slideshows).
set -euo pipefail

if systemctl --user is-active --quiet swayidle; then
  systemctl --user stop swayidle
  notify-send -h string:x-canonical-private-synchronous:caffeine \
    -i caffeine "Caffeine: ON" "Idle & lock disabled"
else
  systemctl --user start swayidle
  notify-send -h string:x-canonical-private-synchronous:caffeine \
    -i sleep "Caffeine: OFF" "Idle & lock active"
fi

# refresh the waybar caffeine indicator immediately (signal 9)
pkill -SIGRTMIN+9 waybar 2>/dev/null || true
