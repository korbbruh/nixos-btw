{ config, lib, pkgs, ... }:

let
  cfg = config.korb.display;
in
{
  # ==========================================================================
  # Per-host display values
  #
  # The swayidle and xwayland-satellite units need the output name and DPI,
  # and those differ per machine. Hosts set these; this module consumes them.
  # ==========================================================================



  options.korb.display = {
    output = lib.mkOption {
      type = lib.types.str;
      description = "Primary output name, e.g. eDP-1 or DP-1.";
    };
    dpi = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = "Xft.dpi for XWayland apps. 96 at 1080p, 144 at 1440p/1.5x.";
    };
    autologinUser = lib.mkOption {
      type = lib.types.str;
      description = "User greetd logs in automatically on boot.";
    };
  };

  config = {

    # ========================================================================
    # Session
    # ========================================================================

    services.xserver.enable = true;

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    programs.mango.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        # Autologin straight into Mango on boot.
        initial_session = {
          command = "mango";
          user = cfg.autologinUser;
        };
        # tuigreet appears only after an explicit logout.
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --cmd mango";
          user = "greeter";
        };
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      wlr.settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.rofi}/bin/rofi -dmenu -p 'select output'";
      };
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [ "wlr" "gtk" ];
    };

    # GTK theming is owned by home-manager plus nwg-look (which creates the
    # gtk-4.0 theme symlinks). Qt apps launched from the compositor read
    # QT_QPA_PLATFORMTHEME from mango's env.conf; the polkit agent gets its
    # own value on its unit, since systemd user services do not inherit the
    # compositor environment.
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    programs.dconf.enable = true;

    # ========================================================================
    # User services
    #
    # autostart.sh starts these explicitly once Mango is up. wantedBy also has
    # systemd attempt them at graphical-session.target, which Mango does not
    # reliably reach. If one starts failing at login with start-limit-hit,
    # add startLimitIntervalSec = 0 to it.
    # ========================================================================

    systemd.user.services.swayosd = {
      description = "SwayOSD server";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
        Restart = "always";
        RestartSec = 1;
      };
    };

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

    # QT_QPA_PLATFORMTHEME is set on the unit because systemd user services
    # do not inherit the compositor's env.conf.
    systemd.user.services.polkit-kde-agent = {
      description = "polkit-kde-authentication-agent-1";
      after = [ "graphical-session.target" ];
      startLimitIntervalSec = 0;
      environment = {
        QT_QPA_PLATFORMTHEME = "gnome";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "always";
        RestartSec = 1;
      };
    };

    # Full store paths throughout: a systemd unit gets a minimal PATH, and
    # mmsg in particular is not reachable from one.
    systemd.user.services.swayidle = {
      description = "Idle management";
      after = [ "graphical-session.target" ];
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.swayidle}/bin/swayidle"
          "timeout 450 '${pkgs.swaylock-effects}/bin/swaylock -f'"
          "timeout 660 '${pkgs.wlr-randr}/bin/wlr-randr --output ${cfg.output} --off'"
          "resume '${pkgs.wlr-randr}/bin/wlr-randr --output ${cfg.output} --on'"
          "timeout 900 'systemctl suspend'"
          "before-sleep '${pkgs.swaylock-effects}/bin/swaylock -f'"
        ];
        Restart = "always";
        RestartSec = 3;
      };
    };

    # System-level: reads input devices directly so the OSD appears for volume
    # and brightness keys without a compositor binding. Needs root.
    systemd.services.swayosd-libinput-backend = {
      description = "SwayOSD libinput backend";
      wantedBy = [ "graphical.target" ];
      partOf = [ "graphical.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}
