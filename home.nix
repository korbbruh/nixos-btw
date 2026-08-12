{ config, pkgs, ... }:
{
  home.username = "kl";
  home.homeDirectory = "/home/kl";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  programs.starship.enable = true;
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd" "cd" ];
  };
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons --group-directories-first -1";
      nixeditconf "nvim ~/nixos/configuration.nix"
      nixeditflake "nvim ~/nixos/flake.nix";
      nixedithome "nvim ~/nixos/home.nix";
    };

    shellAbbrs = {
      lg = "lazygit";
      gd = "git diff";
      ga = "git add .";
      gc = "git commit -am";
      gl = "git log";
      gs = "git status";
      gst = "git stash";
      gsp = "git stash pop";
      gp = "git push";
      gpl = "git pull";
      gsw = "git switch";
      gsm = "git switch main";
      gb = "git branch";
      gbd = "git branch -d";
      gco = "git checkout";
      gsh = "git show";
      l = "ls";
      ll = "ls -l";
      la = "ls -a";
      lla = "ls -la";
    };

    functions = {
      mark_prompt_start = {
        onEvent = "fish_prompt";
        body = ''echo -en "\e]133;A\e\\"'';
      };
    };
  };
}
