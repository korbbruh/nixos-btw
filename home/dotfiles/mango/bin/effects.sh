#!/usr/bin/env bash
# ~/.config/mango/bin/effects.sh
# Toggle compositor effects between FULL (blur/shadows/anim) and PERFORMANCE
# (all off, for battery / gaming / thermals).
#
# How it works: config.conf sources ~/.config/mango/effects.conf. This script
# copies one of the two presets over that file, then reloads mango. State is
# tracked by a marker file so we know which preset is live.
#
# Usage:
#   effects.sh            # toggle
#   effects.sh full       # force full
#   effects.sh performance# force performance
#   effects.sh status     # print current mode
set -euo pipefail

DIR="$HOME/.config/mango"
LIVE="$DIR/effects.conf"
FULL="$DIR/effects-full.conf"
PERF="$DIR/effects-performance.conf"
STATE="$HOME/.cache/mango-effects-mode"

current() { cat "$STATE" 2>/dev/null || echo "full"; }

apply() {
  local mode="$1" src
  case "$mode" in
    full)        src="$FULL" ;;
    performance) src="$PERF" ;;
    *) echo "unknown mode: $mode" >&2; exit 1 ;;
  esac
  cp "$src" "$LIVE"
  printf '%s\n' "$mode" >"$STATE"
  mmsg dispatch reload_config >/dev/null 2>&1 || true
  notify-send -h string:x-canonical-private-synchronous:effects \
    -i preferences-desktop-effects \
    "Effects: ${mode^^}" \
    "$([ "$mode" = performance ] && echo 'Blur/shadows off — battery & gaming' || echo 'Full blur, shadows, animations')"
}

case "${1:-toggle}" in
  full)         apply full ;;
  performance)  apply performance ;;
  status)       current ;;
  toggle)
    if [ "$(current)" = "full" ]; then apply performance; else apply full; fi
    ;;
  *) echo "usage: effects.sh [toggle|full|performance|status]" >&2; exit 1 ;;
esac
