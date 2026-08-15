{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.mangowm.nixosModules.mango
  ];

  #### Boot ####################################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

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
    options = "--delete-older-than 5d";
  };

security.pam.services.swaylock = { };

  #### Packages ################################################

  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    wget
    firefox
    fish
    starship
    eza
    foot
    nwg-look
    lm_sensors
    pavucontrol
    impala
    bluetui
    pamixer
    flatpak
    jq
    wl-clip-persist
    swayidle
    libnotify
    wlsunset
    rofi
    waybar
    mako
    swaybg
    btop
    greetd
    adw-gtk3
    papirus-icon-theme
    papirus-folders
    tuigreet
    fastfetch
    powertop
    swayosd
    swaylock-effects
    tumbler
    bibata-cursors
    thunar
    thunar-archive-plugin
    thunar-vcs-plugin
    thunar-volman
    kdePackages.dolphin
    kdePackages.polkit-kde-agent-1
    cliphist
    wl-clipboard
    sway-audio-idle-inhibit
    bemoji
    xwayland-satellite
    grim
    slurp 
    brightnessctl
];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

xdg.portal = {
  enable = true;
  wlr.enable = true;
  config.common.default = "*";
};

boot.consoleLogLevel = 0;
boot.kernelParams = [ "quiet" "udev.log_level=3" "amdgpu.dcdebugmask=0x40000" ];

services.supergfxd.enable = true;
hardware.bluetooth.enable = true;
services.blueman.enable = true;
services.flatpak.enable = true;
services.tumbler.enable = true;
security.polkit.enable = true;
services.asusd.enable = true;
services.power-profiles-daemon.enable = true;

systemd.user.services.swayosd = {
  description = "SwayOSD server";
  wantedBy = [ "graphical-session.target" ];
  after = [ "graphical-session.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
    Restart = "always";
    RestartSec = 1;
  };
};

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

systemd.user.services.xwayland-satellite = {
  description = "Xwayland outside your Wayland";
  wantedBy = [ "graphical-session.target" ];
  after = [ "graphical-session.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :2";
    ExecStartPost = "${pkgs.writeShellScript "xrdb-dpi" ''
      sleep 1
      DISPLAY=:2 ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: 144"
    ''}";
    Restart = "always";
    RestartSec = 1;
  };
};

systemd.user.services.polkit-kde-agent = {
  description = "polkit-kde-authentication-agent-1";
  wantedBy = [ "graphical-session.target" ];
  wants = [ "graphical-session.target" ];
  after = [ "graphical-session.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
    Restart = "on-failure";
    RestartSec = 1;
  };
};

  #### Do not change ###########################################

  system.stateVersion = "26.05";
}
