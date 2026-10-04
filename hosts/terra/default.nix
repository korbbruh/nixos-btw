{ config, lib, ... }:

# Terra: Ryzen 7 5700X + RX 7800XT, single 1080p monitor.
# Single AMD GPU, no hybrid graphics, no battery, no ASUS anything.

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "terra";

  # Plasma by default here; Mango is still selectable at the greeter.
  # XWayland's default 96 DPI suits 1080p, so no xrdb step.
  services.displayManager.defaultSession = lib.mkForce "plasma";

  users.users."keri" = {
    isNormalUser = true;
    description = "keri";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ==========================================================================
  # Graphics
  #
  # RX 7800XT is RDNA3, driven entirely by mesa/amdgpu. Nothing to configure
  # beyond enabling graphics; no proprietary driver, no offload, no modprobe.
  # ==========================================================================

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ==========================================================================
  # Notes on what is deliberately absent
  #
  # No powertop/asusd/supergfxd: desktop, always on AC. (power-profiles-daemon
  #   and upower ARE on, via common.nix, because Noctalia's widgets need them.)
  # No logind lid handling: no lid.
  # No S0ix modprobe config: that is NVIDIA-specific.
  # ==========================================================================

  # IMPORTANT: leave this at whatever the Terra installer generated. It is not
  # a version to keep current; it pins stateful defaults from first install.
  system.stateVersion = "26.05";
}
