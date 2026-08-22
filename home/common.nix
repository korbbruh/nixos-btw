{ config, pkgs, ... }:

# Shared home-manager config. Per-user files set username/homeDirectory
# and import this.
#
# THEMING BOUNDARY: this manages settings.ini only. Everything theme-pick.sh
# rewrites at runtime (foot/colors.ini, waybar/colors.css, rofi/colors.rasi,
# mango/theme.conf, mako/config, cava/config, yazi/, btop, nvim theme) must
# stay OUT of home-manager, or it becomes a read-only store symlink and the
# script's writes fail. Same for ~/.local/share/icons/Papirus-Dark, which
# papirus-folders recolours in place.

{
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

  xdg.configFile."mango/keybinds.conf".text = ''
  ...whole file contents here...
  bind=SUPER,v,spawn,${config.home.homeDirectory}/.config/mango/clipboard.sh
  ...
'';

  # iconTheme has a name but no package on purpose: GTK then resolves
  # Papirus-Dark through the normal XDG path, where the recoloured copy in
  # ~/.local/share/icons wins over the store one.
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
      dot = "git --git-dir=$HOME/.dotfiles --work-tree=$HOME";

      # No #host: nixos-rebuild picks the config matching the hostname,
      # so this works unchanged on both machines.
      nixup = "cd ~/nixos && nix flake update && sudo nixos-rebuild switch --flake ~/nixos && git add -A && git commit -m 'flake update' && git pull --rebase && git push";

      nixeditflake = "nvim ~/nixos/flake.nix";
      nixedithost = "nvim ~/nixos/hosts/$hostname/default.nix";
      nixeditcommon = "nvim ~/nixos/modules/common.nix";
      nixeditdesktop = "nvim ~/nixos/modules/desktop.nix";
      nixedithome = "nvim ~/nixos/home/common.nix";
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
