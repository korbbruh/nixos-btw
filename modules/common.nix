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
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "en_PH.UTF-8/UTF-8" ];

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
    plugins = with pkgs; [ thunar-archive-plugin thunar-vcs-plugin thunar-volman ];
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;
  services.printing.enable = true;
  services.flatpak.enable = true;

  programs.localsend.enable = true;
  programs.localsend.openFirewall = true;

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
    kdePackages.okular
    kdePackages.kate

    # shell
    fish
    starship
    eza

    # compositor stack
    foot
    xwayland-satellite
    wlr-randr
    wl-clipboard
    brightnessctl # backend Noctalia's brightness OSD drives
    sway-audio-idle-inhibit # Noctalia does not inhibit idle during audio

    # screenshots
    grim
    slurp
    swappy
    wayfreeze

    # system tools
    btop
    fastfetch
    lm_sensors
    jq

    # audio / network / bluetooth TUIs
    pavucontrol
    pamixer
    wiremix
    bluetui

    # apps
    vesktop
    firefox
    spotify
    obsidian
    flatpak
    localsend
    colorpanes
    vlc
    noctalia
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

nixpkgs.overlays = [
  (final: prev: {
    xwayland-satellite = prev.xwayland-satellite.overrideAttrs (old: rec {
      version = "0.8.3";
      src = prev.fetchFromGitHub {
        owner = "Supreeeme";
        repo = "xwayland-satellite";
        rev = "v${version}";
        hash = "sha256-eFEjCCniMCKeWU0PcZNv+tDYe08SLFPjRplyPY8OFt4=";
      };
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-gMGFvnbxM3hD5fmkSimaFd87GEf6BXFe/MGjoS6VNVU=";
      };
      __intentionallyOverridingVersion = true;
    });
  })
];
}
