{ config, pkgs, ... }:
{
  imports = [ ./common.nix ];

  home.username = "kl";
  home.homeDirectory = "/home/kl";
}
