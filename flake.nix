{
  description = "MangoWM on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # Shared across every host: the modules that define what a "korb machine"
      # is, plus home-manager wiring.
      base = [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
        }
        ./modules/common.nix
        ./modules/desktop.nix
      ];
    in
    {
      nixosConfigurations = {

        nixos-btw = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = base ++ [
            inputs.nixos-hardware.nixosModules.asus-zephyrus-ga503
            ./hosts/g15
            { home-manager.users.kl = import ./home/kl.nix; }
          ];
        };

        terra = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = base ++ [
            ./hosts/terra
            { home-manager.users.keri = import ./home/keri.nix; }
          ];
        };

      };
    };
}
