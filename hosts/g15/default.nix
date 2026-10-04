{ config, lib, pkgs, ... }:

# ASUS ROG Zephyrus G15 GA503QR
# AMD Renoir iGPU + RTX 3070 Mobile in PRIME offload, 2560x1440 165Hz eDP-1.

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-btw";

  # ==========================================================================
  # Display
  # ==========================================================================

  services.displayManager.defaultSession = lib.mkForce "mango";

  # 1440p panel at 1.5x: tell XWayland apps 144 DPI so they aren't tiny.
  systemd.user.services.xwayland-satellite.serviceConfig.ExecStartPost =
    "${pkgs.writeShellScript "xrdb-dpi" ''
      sleep 1
      DISPLAY=:2 ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: 144"
    ''}";

  users.users."kl" = {
    isNormalUser = true;
    description = "k.l";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ==========================================================================
  # Boot
  # ==========================================================================
  # DynamicPowerManagement and PreserveVideoMemoryAllocations are NOT set here;
  # hardware.nvidia.powerManagement.{enable,finegrained} already set them.
  boot.extraModprobeConfig = ''
    options nvidia NVreg_EnableS0ixPowerManagement=1
  '';

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
  # Power (laptop-only; power-profiles-daemon and upower are in common.nix)
  # ==========================================================================

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
  services.asusd.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  environment.systemPackages = with pkgs; [
    powertop
  ];

  system.stateVersion = "26.05";
}
