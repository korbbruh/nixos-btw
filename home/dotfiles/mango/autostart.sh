#!/usr/bin/env bash
# SUPERSEDED: idle management now lives in systemd.user.services.swayidle
# in ~/nixos/configuration.nix. Editing this file does nothing.

#lockscreen
#swaylock &

# --- environment ---
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
systemctl --user start mango-session.target &
systemctl --user start polkit-kde-agent &
systemctl --user start swayosd &
systemctl --user start xwayland-satellite &

# --- bar + notifications ---
waybar -c ~/.config/mango/config.jsonc &
mako &

# --- clipboard history (feeds clipboard.sh via cliphist) ---
wl-clip-persist --clipboard regular --reconnect-tries 0 &
wl-paste --type text --watch cliphist store >/dev/null &
wl-paste --type image --watch cliphist store >/dev/null &

# --- idle / lock / nightlight ---
systemctl --user start swayidle &
#~/.config/mango/bin/idle.sh &
#~/.config/mango/bin/nightlight.sh &
sway-audio-idle-inhibit >/dev/null & # don't idle while audio plays

# --- wallpaper ---
# Restore the last wallpaper; fall back to a default so you never cold-boot
# to a black screen before the first theme switch.
WALL_STATE="$HOME/.cache/current-wallpaper"
if [ -r "$WALL_STATE" ] && [ -f "$(cat "$WALL_STATE")" ]; then
  swaybg -m fill -i "$(cat "$WALL_STATE")" >/dev/null 2>&1 &
else
  swaybg -m fill -i ~/Pictures/Wallpapers/abstract-grayscale-layered-wavy-shapes.jpg >/dev/null 2>&1 &
fi
