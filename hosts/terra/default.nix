{ config, pkgs, ... }:

# Terra: Ryzen 7 5700X + RX 7800XT, single 1080p monitor.
# Single AMD GPU, no hybrid graphics, no battery, no ASUS anything.

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "terra";

  korb.display = {
    # TODO: confirm with `wlr-randr` on Terra. Likely DP-1 or HDMI-A-1.
    output = "DP-1";
    dpi = 96; # 1080p, no scaling
    autologinUser = "keri";
  };

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
  # Networking
  #
  # Ethernet, so plain NetworkManager. No iwd, no regulatory domain, no
  # impala. Add them back here if you put a wifi card in.
  # ==========================================================================

  networking.networkmanager.enable = true;

  # ==========================================================================
  # Notes on what is deliberately absent
  #
  # No powertop/PPD/upower/asusd/supergfxd: desktop, always on AC.
  # No logind lid handling: no lid.
  # No amdgpu.dcdebugmask: that flag is for the G15's panel quirk only.
  # No S0ix modprobe config: that is NVIDIA-specific.
  # ==========================================================================

  # IMPORTANT: leave this at whatever the Terra installer generated. It is not
  # a version to keep current; it pins stateful defaults from first install.
  system.stateVersion = "26.05"; # TODO: set to Terra's actual install version
}
