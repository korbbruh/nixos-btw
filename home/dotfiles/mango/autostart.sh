#!/usr/bin/env bash
# ~/.config/mango/autostart.sh
#
# Mango does not reach graphical-session.target on its own, so the
# import-environment + mango-session.target lines are what make portals and
# user services work. Everything else (bar, OSD, notifications, polkit, idle,
# lock, wallpaper, clipboard, nightlight) is Noctalia's job.

systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
systemctl --user start mango-session.target &
systemctl --user start xwayland-satellite &

noctalia &
sway-audio-idle-inhibit >/dev/null 2>&1 & # Noctalia does not do this
