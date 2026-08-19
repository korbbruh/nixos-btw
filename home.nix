{ config, pkgs, ... }:
{
  home.username = "kl";
  home.homeDirectory = "/home/kl";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  programs.starship.enable = true;
  services.ssh-agent.enable = true;
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd" "cd" ];
  };
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };
  gtk = {
  enable = true;
  theme = {
    name = "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };
  iconTheme = {
  name = "Papirus-Dark";
  };
};

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons --group-directories-first -1";
      nixeditconf = "nvim ~/nixos/configuration.nix";
      nixeditflake = "nvim ~/nixos/flake.nix";
      nixedithome =  "nvim ~/nixos/home.nix";
      nixup = "cd ~/nixos && nix flake update && sudo nixos-rebuild switch --flake ~/nixos#nixos-btw && git add -A && git commit -m 'flake update' && git pull --rebase && git push";
      dot = "git --git-dir=$HOME/.dotfiles --work-tree=$HOME";
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
