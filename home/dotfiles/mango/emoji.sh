#!/usr/bin/env bash
# ~/.config/mango/emoji.sh
# Emoji picker via bemoji, using rofi + wl-copy. Copy-to-clipboard mode.
#   yay -S bemoji wl-clipboard
set -euo pipefail

export BEMOJI_PICKER_CMD="rofi -dmenu -theme dmenu -p emoji"
export BEMOJI_CLIP_CMD="wl-copy"
bemoji
