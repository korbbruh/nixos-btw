{ config, pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.username = "keri";
  home.homeDirectory = "/home/keri";
}
