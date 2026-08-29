sudo cp /etc/nixos/hardware-configuration.nix ~/hw-backup.nix
git clone git@github.com:korbbruh/nixos-btw.git ~/nixos
cp ~/hw-backup.nix ~/nixos/hardware-configuration.nix
cd ~/nixos
git add -A
sudo nixos-rebuild switch --flake ~/nixos#nixos-btw

The hardware-configuration.nix step is the one that matters. It holds filesystem UUIDs and disk layout specific to that install. The one in your repo is the G15's current disk. Copy the freshly generated one over it or you won't boot.

Hostname has to match too. The flake defines nixos-btw, so either set that hostname during install or use --flake ~/nixos#nixos-btw explicitly, which works regardless.


# Papirus recolouring needs a writable user-owned copy of BOTH themes:
# Papirus-Dark symlinks into Papirus, so copying only Dark breaks it.
p=$(nix build nixpkgs#papirus-icon-theme --no-link --print-out-paths)
cp -a $p/share/icons/Papirus ~/.local/share/icons/
cp -a $p/share/icons/Papirus-Dark ~/.local/share/icons/
chmod -R u+w ~/.local/share/icons/Papirus{,-Dark}
