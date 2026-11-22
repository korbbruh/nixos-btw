# ~/.config/fish/config.fish
# Ported from home/common.nix (programs.fish). Nix rebuild aliases dropped.

if status is-interactive
    # --- aliases ---
    alias ls 'eza --icons --group-directories-first -1'

    # Arch replacements for the old nix* aliases (Claude's additions, delete if unwanted)
    alias up 'paru -Syu'
    alias dotpush 'cd ~/nixos && git add -A && git commit && git pull --rebase && git push'

    # --- abbreviations ---
    abbr -a lg lazygit
    abbr -a gd 'git diff'
    abbr -a ga 'git add .'
    abbr -a gc 'git commit -am'
    abbr -a gl 'git log'
    abbr -a gs 'git status'
    abbr -a gst 'git stash'
    abbr -a gsp 'git stash pop'
    abbr -a gp 'git push'
    abbr -a gpl 'git pull'
    abbr -a gsw 'git switch'
    abbr -a gsm 'git switch main'
    abbr -a gb 'git branch'
    abbr -a gbd 'git branch -d'
    abbr -a gco 'git checkout'
    abbr -a gsh 'git show'
    abbr -a l ls
    abbr -a ll 'ls -l'
    abbr -a la 'ls -a'
    abbr -a lla 'ls -la'
end

# OSC 133 prompt marker so foot can jump between prompts
function mark_prompt_start --on-event fish_prompt
    echo -en "\e]133;A\e\\"
end
