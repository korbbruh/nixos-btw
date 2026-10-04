{ config, pkgs, ... }:

# Everything here is true of every machine, regardless of hardware.
# Anything that depends on the specific box belongs in hosts/<name>/.

{
  # ==========================================================================
  # Boot (hardware-agnostic parts)
  # ==========================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tracks whatever nixpkgs calls latest. A flake update can land on a kernel
  # an out-of-tree module hasn't caught up to; the rebuild fails loudly if so.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.consoleLogLevel = 0;
  boot.kernelParams = [ "quiet" "udev.log_level=3" ];

  # ==========================================================================
  # Locale
  # ==========================================================================

  time.timeZone = "Asia/Manila";
  i18n.defaultLocale = "en_US.UTF-8";

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
  # Networking
  # ==========================================================================

  networking = {
    # Router DNS at 192.168.1.254 was resolving in 5-8 SECONDS. Bypassing it
    # took lookups to ~20ms. dns = "none" stops NM reinstating the router's
    # resolver from DHCP while still taking its IP lease.
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    networkmanager = {
      enable = true; # also required by Noctalia's wifi widget
      dns = "none";
    };
  };

  hardware.bluetooth.enable = true; # required by Noctalia's bluetooth widget

  # ==========================================================================
  # Power
  #
  # Both required by Noctalia's power-profile and battery widgets, on desktop
  # as well as laptop. Laptop-only tuning stays in hosts/g15.
  # ==========================================================================

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # ==========================================================================
  # Files / desktop services
  # ==========================================================================

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-volman ];
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;
  services.flatpak.enable = true;

  programs.localsend.enable = true;
  programs.localsend.openFirewall = true;

  # ==========================================================================
  # Graphics
  # ==========================================================================

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ==========================================================================
  # Gaming
  # ==========================================================================

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # ==========================================================================
  # Shell
  # ==========================================================================

  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

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
  #
  # Noctalia provides the bar, launcher, OSD, notifications, notification
  # centre, polkit agent, idle management, lock screen, wallpaper, clipboard,
  # nightlight, system monitor, weather, dock and GTK theming. Anything it
  # covers is deliberately absent below.
  # ==========================================================================

  environment.systemPackages = with pkgs; [
    # editors / core
    neovim
    git
    tuigreet
    kdePackages.okular
    kdePackages.kate

    # shell
    eza

    # compositor stack
    foot
    xwayland-satellite
    wl-clipboard
    brightnessctl # backend Noctalia's brightness OSD drives

    # screenshots
    grim
    slurp
    swappy

    # system tools
    btop
    fastfetch
    lm_sensors

    # audio / network / bluetooth TUIs
    wiremix
    bluetui

    # theming
    adw-gtk3 # Noctalia's gtk3/gtk4 templates switch to it; without it they silently skip
    papirus-icon-theme
    colorpanes

    # apps
    vesktop
    firefox
    spotify
    obsidian
    vlc
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
