{ config, pkgs, ... }:

# ASUS ROG Zephyrus G15 GA503QR
# AMD Renoir iGPU + RTX 3070 Mobile in PRIME offload, 2560x1440 165Hz eDP-1.

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-btw";

  korb.display = {
    output = "eDP-1";
    dpi = 144; # 1440p at 1.5x scaling
    autologinUser = "kl";
  };

  users.users."kl" = {
    isNormalUser = true;
    description = "k.l";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ==========================================================================
  # Boot
  # ==========================================================================

  # Panel dims instead of brightening above ~95% backlight without this.
  # Confirmed a hardware/driver quirk: reproduces on CachyOS too.
  boot.kernelParams = [ "amdgpu.dcdebugmask=0x40000" ];

  # DynamicPowerManagement and PreserveVideoMemoryAllocations are NOT set here;
  # hardware.nvidia.powerManagement.{enable,finegrained} already set them.
  boot.extraModprobeConfig = ''
    options nvidia NVreg_EnableS0ixPowerManagement=1
  '';

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
  # Networking
  # ==========================================================================

  #networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  # ==========================================================================
  # Power
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

  environment.systemPackages = with pkgs; [
    powertop
    upower
  ];

  system.stateVersion = "26.05";
}
