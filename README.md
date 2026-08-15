sudo cp /etc/nixos/hardware-configuration.nix ~/hw-backup.nix
git clone git@github.com:korbbruh/nixos-btw.git ~/nixos
cp ~/hw-backup.nix ~/nixos/hardware-configuration.nix
cd ~/nixos
git add -A
sudo nixos-rebuild switch --flake ~/nixos#nixos-btw
