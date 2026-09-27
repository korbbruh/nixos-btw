{ config, lib, pkgs, ... }:

let
  cfg = config.korb.display;
in
{
  # ==========================================================================
  # Per-host display values
  #
  # xwayland-satellite needs the DPI, and the greeter/autologin needs the user
  # and session. Those differ per machine; hosts set them, this module uses
  # them.
  # ==========================================================================

  options.korb.display = {
    output = lib.mkOption {
      type = lib.types.str;
      description = "Primary output name, e.g. eDP-1 or DP-2.";
    };
    dpi = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = "Xft.dpi for XWayland apps. 96 at 1080p, 144 at 1440p/1.5x.";
    };
    autologinUser = lib.mkOption {
      type = lib.types.str;
      description = "User the display manager logs in automatically on boot.";
    };
    autologinSession = lib.mkOption {
      type = lib.types.str;
      default = "mango";
      description = "Session the display manager defaults to.";
    };
  };

  config = {

    # ========================================================================
    # Compositors
    #
    # Mango is the daily driver. Plasma is kept for presenting and for the
    # days when debugging is not an option. Niri is an experiment.
    # ========================================================================

    services.xserver.enable = true;

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    programs.mango.enable = true;
    programs.niri.enable = true;
    services.desktopManager.plasma6.enable = true;

    services.displayManager.defaultSession = lib.mkForce cfg.autologinSession;

    # ========================================================================
    # Noctalia
    #
    # Provides bar, launcher, OSD, notifications + centre, polkit agent, idle,
    # lock, wallpaper, clipboard, nightlight, system monitor, weather, dock
    # and GTK theming. recommendedServices pulls in what it needs.
    #
    # Its widgets also need networkmanager, bluetooth, power-profiles-daemon
    # and upower, all enabled in modules/common.nix.
    # ========================================================================

    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = true;
    };

    services.displayManager.noctalia-greeter = {
      enable = true;
      settings = {
        cursor.size = 24;
        keyboard.layout = "us";
      };
      cursorTheme = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
      };
    };

    # ========================================================================
    # Portals
    #
    # wlr's screencast has no UI of its own, so it shells out to a chooser.
    # slurp means "click the output you want to share".
    # ========================================================================

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

    # ========================================================================
    # User services
    #
    # Mango does not reach graphical-session.target on its own, which is what
    # portals depend on. mango-session.target is pulled in from autostart.sh
    # with:
    #   systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    #   systemctl --user start mango-session.target
    # ========================================================================

    systemd.user.targets.mango-session = {
      description = "mango compositor session";
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.xwayland-satellite = {
      description = "Xwayland outside your Wayland";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :2";
        ExecStartPost = "${pkgs.writeShellScript "xrdb-dpi" ''
          sleep 1
          DISPLAY=:2 ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: ${toString cfg.dpi}"
        ''}";
        Restart = "always";
        RestartSec = 1;
      };
    };
  };
}
