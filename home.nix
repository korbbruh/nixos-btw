{ config, pkgs, ... }:
{
  home.username = "kl";
  home.homeDirectory = "/home/kl";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza --icons --group-directories-first -1";
      neofetch = "fastfetch -c /examples/13";
    };
  };
}
