{
  description = "Multi-platform Nix Configuration (NixOS Desktop & MacBooks)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homelab media server (Jellyfin + Arr stack). All of its system config
    # lives in that repo's flake; this config only imports the module.
    # After changing that repo: `nix flake update media-server` here.
    media-server = {
      url = "git+ssh://git@github.com/scott96707/media-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homelab network layer (AdGuard Home DNS + Caddy reverse proxy). Same
    # pattern as media-server: all system config lives in that repo's flake.
    # After changing that repo: `nix flake update homelab-network` here.
    homelab-network = {
      url = "git+ssh://git@github.com/scott96707/homelab-network";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      sops-nix,
      nix-vscode-extensions,
      ...
    }:
    {
      # `nix fmt` formats the whole repo with the same nixfmt already
      # configured as the editor formatter (nixfmt-tree wraps nixfmt in
      # treefmt so it can walk the tree; bare nixfmt only reads stdin).
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
        x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.nixfmt-tree;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
      };

      # --- 1. LINUX PC (NixOS) ---
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos/configuration.nix
          inputs.media-server.nixosModules.media-server
          inputs.homelab-network.nixosModules.homelab-network
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # If activation would clobber a file it doesn't own, move it
            # aside as *.hm-backup instead of failing.
            home-manager.backupFileExtension = "hm-backup";
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
            home-manager.backupFileExtension = "hm-backup";
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
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.${(import ./hosts/macbook-arm/local.nix).username} =
              import ./hosts/macbook-arm/home.nix;
          }
          sops-nix.darwinModules.sops
        ];
      };
    };
}
