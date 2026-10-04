{ pkgs, ... }:

{
  # ==========================================================================
  # Compositors
  #
  # Mango is the daily driver. Plasma is kept for presenting and for the
  # days when debugging is not an option. Niri is an experiment.
  # Each host picks its default session in hosts/<n>/default.nix.
  # ==========================================================================

  services.xserver.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.mango.enable = true;
  programs.niri.enable = true;
  programs.hyprland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ==========================================================================
  # Noctalia
  #
  # Provides bar, launcher, OSD, notifications + centre, polkit agent, idle,
  # lock, wallpaper, clipboard, nightlight, system monitor, weather, dock
  # and GTK theming. recommendedServices pulls in what it needs.
  #
  # Its widgets also need networkmanager, bluetooth, power-profiles-daemon
  # and upower, all enabled in modules/common.nix.
  # ==========================================================================

  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true; 
  };

  services.greetd = {
  enable = true;
  settings = {
    initial_session = {
      command = "mango";
      user = "kl"; # auto-login on first start, no password required
    };
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --cmd mango";
      user = "greeter";
    };
  };
};

  # ==========================================================================
  # Portals
  #
  # wlr's screencast has no UI of its own, so it shells out to a chooser.
  # slurp means "click the output you want to share".
  # ==========================================================================

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    wlr.settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
  };

  programs.dconf.enable = true;

  # ==========================================================================
  # User services
  #
  # Mango does not reach graphical-session.target on its own, which is what
  # portals depend on. mango-session.target is pulled in from autostart.sh
  # with:
  #   systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
  #   systemctl --user start mango-session.target
  # ==========================================================================

  systemd.user.targets.mango-session = {
    description = "mango compositor session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  # XWayland apps default to 96 DPI. A host that needs more (the G15's
  # 1440p panel) adds an ExecStartPost to this unit in its own file.
  systemd.user.services.xwayland-satellite = {
    description = "Xwayland outside your Wayland";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    startLimitIntervalSec = 0;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :2";
      Restart = "always";
      RestartSec = 1;
    };
  };
}
