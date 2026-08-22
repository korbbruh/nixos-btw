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

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ==========================================================================
  # Gaming
  # ==========================================================================

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # ==========================================================================
  # Shell / security
  # ==========================================================================

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
    options = "--delete-older-than 14d";
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
    swappy

    # theming
    adw-gtk3
    papirus-icon-theme
    papirus-folders
    nwg-look # creates the gtk-4.0 theme symlinks home-manager doesn't
    glib
    gsettings-desktop-schemas

    # session
    greetd
    tuigreet
    kdePackages.polkit-kde-agent-1

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
    firefox
    spotify
    flatpak
    bemoji
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
