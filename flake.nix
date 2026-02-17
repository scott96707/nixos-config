{
  description = "Multi-platform Nix Configuration (NixOS Desktop & MacBooks)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, sops-nix, ... }: {

    # --- 1. LINUX PC (NixOS) ---
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nixos/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.home = import ./hosts/nixos/home.nix;
        }
        sops-nix.nixosModules.sops
      ];
    };

    # --- 2a. MACBOOK (Intel) ---
    darwinConfigurations."macbook-intel" = nix-darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/macbook/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.work_machine = import ./hosts/macbook/home.nix;
        }
        sops-nix.darwinModules.sops
      ];
    };

    # --- 2b. MACBOOK (Apple Silicon / ARM) ---
    darwinConfigurations."macbook-arm" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/macbook-arm/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.work_machine = import ./hosts/macbook-arm/home.nix;
        }
        sops-nix.darwinModules.sops
      ];
    };
  };
}
