#!/usr/bin/env bash
# ~/.config/mango/autostart.sh
#
# Mango does not reach graphical-session.target on its own. These two lines
# give the user manager the Wayland environment, then pull the target in, which
# is what portals and xwayland-satellite (wantedBy graphical-session.target)
# wait for. They run in order, NOT backgrounded: the target must not start
# before the environment is imported.
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
systemctl --user start mango-session.target &

# Noctalia's FAQ: it doesn't manage its own autostart; use the compositor's.
# (So programs.noctalia.systemd is off in desktop.nix: one launcher only.)
noctalia &
noctalia msg session lock >/dev/null 2>&1
