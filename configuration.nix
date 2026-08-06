{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.mangowm.nixosModules.mango
  ];

  #### Boot ####################################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Deliberately NOT using linuxPackages_latest.
  # The newest mainline kernel regularly outruns the proprietary
  # NVIDIA module and breaks the build. Default kernel is fine.

  #### Networking ##############################################

  networking.hostName = "nixos-btw";
  networking.networkmanager.enable = true;

  #### Locale ##################################################

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

  #### Display / desktop #######################################

  services.xserver.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # SDDM only. The greetd block that used to be here fought with
  # this one, and greetd's hardcoded "--cmd mango" meant a broken
  # Mango left you with no way back into a working session.
  # SDDM gives a session dropdown, so Plasma is always a fallback.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.mango.enable = true;

  # Graphics. Running on amdgpu alone right now.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  #### Audio ###################################################

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  #### Printing ################################################

  services.printing.enable = true;

  #### Users ###################################################

  users.users."kl" = {
    isNormalUser = true;
    description = "k.l";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  #### Nix itself ##############################################

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  #### Packages ################################################

  environment.systemPackages = with pkgs; [
    # editors / core
    vim
    neovim
    git
    wget
    firefox

    # shell + prompt
    fish
    starship
    eza

    # terminals
    foot

    # wayland / rice stack
    rofi
    waybar
    mako
    swaybg

    # system tools
    btop
    fastfetch
    powertop

    # files
    xfce.thunar
    thunar-volman
    thunar-archive-plugin

    # toys
    cmatrix
    tty-clock
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

systemd.user.services.polkit-gnome-authentication-agent-1 = {
  description = "polkit-gnome-authentication-agent-1";
  wantedBy = [ "graphical-session.target" ];
  wants = [ "graphical-session.target" ];
  after = [ "graphical-session.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    Restart = "on-failure";
    RestartSec = 1;
    TimeoutStopSec = 10;
  };
};
  #### Do not change ###########################################

  system.stateVersion = "26.05";
}
