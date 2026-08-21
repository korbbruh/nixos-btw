{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.mangowm.nixosModules.mango
  ];

  # ==========================================================================
  # Boot
  # ==========================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tracks whatever nixpkgs calls latest. A flake update can land on a kernel
  # the NVIDIA module hasn't caught up to; the rebuild fails loudly if so.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.consoleLogLevel = 0;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
    # Fixes the panel dimming instead of brightening above ~95% backlight.
    "amdgpu.dcdebugmask=0x40000"
  ];

  # DynamicPowerManagement and PreserveVideoMemoryAllocations are NOT set here;
  # hardware.nvidia.powerManagement.{enable,finegrained} already set them.
  boot.extraModprobeConfig = ''
    options nvidia NVreg_EnableS0ixPowerManagement=1
  '';

  # ==========================================================================
  # Networking
  # ==========================================================================

  networking.hostName = "nixos-btw";

  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd"; # impala talks to iwd, not wpa_supplicant
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = false; # NetworkManager owns IP/DNS
      Rank.BandModifier5GHz = 2.0;
      General.Country = "PH";
    };
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ==========================================================================
  # Locale
  # ==========================================================================

  time.timeZone = "Asia/Manila";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # ==========================================================================
  # Graphics
  # ==========================================================================

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # PRIME offload: compositor runs on the AMD iGPU, the 3070 sits in runtime
  # D3 until something explicitly asks for it.
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # runtime D3
    open = true; # open kernel modules, correct for Ampere on kernel >= 6.11
  };

  services.supergfxd.enable = true;

  # ==========================================================================
  # Display / session
  # ==========================================================================

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
        user = "kl";
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
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
  };

  # GTK theming is owned by home-manager (home.nix). Qt apps launched from the
  # compositor pick up QT_QPA_PLATFORMTHEME=gtk3 from mango's env.conf; the
  # polkit agent gets its own value on its unit since systemd user services
  # don't inherit the compositor environment.
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  programs.dconf.enable = true;

  # ==========================================================================
  # Audio
  # ==========================================================================

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ==========================================================================
  # Power (laptop)
  # ==========================================================================

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.asusd.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # ==========================================================================
  # Files / desktop services
  # ==========================================================================

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-vcs-plugin thunar-volman ];
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;
  services.printing.enable = true;
  services.flatpak.enable = true;

  # ==========================================================================
  # Gaming
  # ==========================================================================

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # ==========================================================================
  # Users / security
  # ==========================================================================

  users.users."kl" = {
    isNormalUser = true;
    description = "k.l";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  security.polkit.enable = true;
  security.pam.services.swaylock = { };

  # ==========================================================================
  # Nix
  # ==========================================================================

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # ==========================================================================
  # Packages
  # ==========================================================================

  environment.systemPackages = with pkgs; [
    # editors / core
    vim
    neovim
    git
    wget
    kdePackages.kate

    # shell
    fish
    starship
    eza

    # compositor stack
    foot
    rofi
    waybar
    mako
    swaybg
    swayidle
    swaylock-effects
    swayosd
    xwayland-satellite
    wlr-randr
    wl-clipboard
    wl-clip-persist
    cliphist
    sway-audio-idle-inhibit
    wlsunset
    libnotify
    brightnessctl

    # screenshots
    grim
    slurp
    satty

    # theming
    adw-gtk3
    papirus-icon-theme
    papirus-folders
    nwg-look # NOTE: cannot write GTK settings, home-manager owns them
    glib
    gsettings-desktop-schemas

    # session
    greetd
    tuigreet
    kdePackages.polkit-kde-agent-1

    # system tools
    btop
    fastfetch
    powertop
    upower
    lm_sensors
    jq

    # audio / network / bluetooth TUIs
    pavucontrol
    pamixer
    wiremix
    impala
    bluetui

    # apps
    vlc
    firefox
    spotify
    flatpak
    bemoji
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # ==========================================================================
  # User services
  #
  # autostart.sh starts these explicitly once Mango is up. wantedBy also has
  # systemd attempt them at graphical-session.target, which Mango does not
  # reliably reach -- if those early attempts fail fast enough to trip the
  # default start limit, the unit stays dead. Add startLimitIntervalSec = 0
  # to any of these that starts failing at login.
  # ==========================================================================

  systemd.user.services.swayosd = {
    description = "SwayOSD server";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "always";
      RestartSec = 1;
    };
  };

  systemd.user.services.xwayland-satellite = {
    description = "Xwayland outside your Wayland";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :2";
      ExecStartPost = "${pkgs.writeShellScript "xrdb-dpi" ''
        sleep 1
        DISPLAY=:2 ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: 144"
      ''}";
      Restart = "always";
      RestartSec = 1;
    };
  };

  # QT_QPA_PLATFORMTHEME is set on the unit because systemd user services do
  # not inherit the compositor's env.conf.
  systemd.user.services.polkit-kde-agent = {
    description = "polkit-kde-authentication-agent-1";
    after = [ "graphical-session.target" ];
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

  # Full store paths throughout: a systemd unit gets a minimal PATH, and mmsg
  # in particular is not reachable from one.
  systemd.user.services.swayidle = {
    description = "Idle management";
    after = [ "graphical-session.target" ];
    startLimitIntervalSec = 0;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.swayidle}/bin/swayidle timeout 450 '${pkgs.swaylock-effects}/bin/swaylock -f' timeout 660 '${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --off' resume '${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --on' timeout 900 'systemctl suspend' before-sleep '${pkgs.swaylock-effects}/bin/swaylock -f'";
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

  # ==========================================================================
  # Do not change
  # ==========================================================================

  system.stateVersion = "26.05";
}
