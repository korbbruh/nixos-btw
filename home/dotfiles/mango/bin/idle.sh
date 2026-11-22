#!/usr/bin/env bash
# ~/.config/mango/bin/idle.sh
LOCK="swaylock -f"
PANEL="eDP-1"
exec swayidle \
  timeout 450 "$LOCK" \
  timeout 660 "mmsg dispatch disable_monitor,$PANEL" \
  resume "mmsg dispatch enable_monitor,$PANEL" \
  timeout 900 "systemctl suspend" \
  before-sleep "$LOCK"
