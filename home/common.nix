{ config, pkgs, ... }:

# Shared home-manager config. Per-user files set username/homeDirectory
# and import this.
#
# DOTFILES: everything under home/dotfiles/ is linked with
# mkOutOfStoreSymlink, so ~/.config/<x> points at a WRITABLE path inside this
# repo rather than a read-only store path. Edits take effect immediately with
# no rebuild, and tools that rewrite their own config at runtime keep working.
#
# GTK theming is owned by Noctalia now, not this file.

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

  # ==========================================================================
  # Dotfiles
  # ==========================================================================

  xdg.configFile."mango".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/dotfiles/mango";

  xdg.configFile."foot".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/dotfiles/foot";

  xdg.configFile."btop".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/dotfiles/btop";

  # Noctalia writes its own settings at runtime, so this must stay writable.
  xdg.configFile."noctalia".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/home/dotfiles/noctalia";

  # ==========================================================================
  # Fish
  # ==========================================================================

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons --group-directories-first -1";

      # --- editing ---
      nixeditflake = "nvim ~/nixos/flake.nix";
      nixeditg15 = "nvim ~/nixos/hosts/g15/default.nix";
      nixeditterra = "nvim ~/nixos/hosts/terra/default.nix";
      nixeditcommon = "nvim ~/nixos/modules/common.nix";
      nixeditdesktop = "nvim ~/nixos/modules/desktop.nix";
      nixedithome = "nvim ~/nixos/home/common.nix";

      # --- rebuild ---
      # No #host: nixos-rebuild picks the config matching the hostname.
      nixre = "sudo nixos-rebuild switch --flake ~/nixos";
      nixpush = "cd ~/nixos && sudo nixos-rebuild switch --flake ~/nixos && git add -A && git commit && git pull --rebase && git push";
      nixpull = "cd ~/nixos && git pull && sudo nixos-rebuild switch --flake ~/nixos";
      # Weekly, and on ONE machine only: both regenerating flake.lock from the
      # same parent conflicts every time. The other machine uses nixpull.
      nixup = "cd ~/nixos && nix flake update && sudo nixos-rebuild switch --flake ~/nixos && git add -A && git commit -m 'flake update' && git pull --rebase && git push";
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
