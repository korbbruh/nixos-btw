#!/usr/bin/env bash
# ~/.config/mango/bin/refresh-power.sh
# Auto refresh rate for the LAPTOP PANEL ONLY (eDP-1):
#   AC      -> restore native 165Hz via compositor config reload (clean path)
#   battery -> wlr-randr sets 60Hz (safe; 165 via wlr-randr corrupts this panel)
# External monitors are never touched (they don't draw laptop battery).
set -euo pipefail

OUTPUT="eDP-1"
AC="/sys/class/power_supply/AC0/online"

on_ac() { [ -r "$AC" ] && [ "$(cat "$AC")" = "1" ]; }

set_60() {
  wlr-randr --output "$OUTPUT" --mode "2560x1440@60Hz" 2>/dev/null || true
}

restore_native() {
  # Reapplies monitor.conf (eDP-1 @165). Compositor's own clean modeset path.
  mmsg dispatch reload_config >/dev/null 2>&1 || true
}

case "${1:-auto}" in
  60)   set_60 ;;
  165)  restore_native ;;
  auto) if on_ac; then restore_native; else set_60; fi ;;
  *)    echo "usage: refresh-power.sh [auto|60|165]" >&2; exit 1 ;;
esac
