#!/usr/bin/env bash
# ~/.config/mango/bin/micmute.sh
# swayosd's --input-volume mute-toggle doesn't flip state reliably, but raw
# wpctl does. So toggle with wpctl, then show the OSD reflecting the result.
set -euo pipefail

SRC="@DEFAULT_AUDIO_SOURCE@"

wpctl set-mute "$SRC" toggle

# Read back the real state and show the matching OSD.
if wpctl get-volume "$SRC" | grep -q MUTED; then
  swayosd-client --custom-message "Mic muted" --custom-icon microphone-disabled-symbolic 2>/dev/null ||
    swayosd-client --input-volume mute-toggle
else
  swayosd-client --custom-message "Mic on" --custom-icon microphone-sensitivity-high-symbolic 2>/dev/null ||
    swayosd-client --input-volume mute-toggle
fi
