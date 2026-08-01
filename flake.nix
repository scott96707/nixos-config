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
      # Pinned to the last revision before upstream dropped x86_64-darwin
      # (commit 435c758, 2026-07-22). This MacBook is an Intel Mac, so newer
      # revisions crash the overlay with `attribute 'x86_64-darwin' missing`.
      # Unpin once this host moves off x86_64-darwin (EOL: nixpkgs 26.05).
      url = "github:nix-community/nix-vscode-extensions/1c7bb95446387973178363916a51b14515fa5ee4";
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

    # Manga library tracker/reader (Flask). Same pattern: the repo's flake
    # exports the service module. After changing that repo:
    # `nix flake update manga-aggregator` here.
    manga-aggregator = {
      url = "git+ssh://git@github.com/scott96707/manga-aggregator";
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
    let
      # Module list shared by the deployed Pi system and its SD-image build,
      # so the two can't drift. images.pi layers the sd-image-aarch64 module
      # on top of this to add the bootable-image machinery; the deployed
      # system itself doesn't need it.
      piModules = [
        ./hosts/pi/configuration.nix
        inputs.homelab-network.nixosModules.homelab-network
        sops-nix.nixosModules.sops
      ];
    in
    {
      # `nix fmt` formats the whole repo with the same nixfmt already
      # configured as the editor formatter (nixfmt-tree wraps nixfmt in
      # treefmt so it can walk the tree; bare nixfmt only reads stdin).
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
        x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.nixfmt-tree;
      };

      # --- 1. LINUX PC (NixOS) ---
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos/configuration.nix
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

      # --- 1a. MSI PRO DP21 (NixOS, media appliance) ---
      # Headless media box (see ~/projects/media-server): Jellyfin + Arr
      # stack with Intel QuickSync transcoding, plus the homelab Prometheus
      # server (the Pi is scrape-target-only). No home-manager: appliance,
      # same reasoning as the Pi. Hardware specs are commented at the top
      # of hosts/dp21/configuration.nix.
      nixosConfigurations.dp21 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/dp21/configuration.nix
          inputs.media-server.nixosModules.media-server
          inputs.homelab-network.nixosModules.homelab-network
          inputs.manga-aggregator.nixosModules.manga-aggregator
          sops-nix.nixosModules.sops
        ];
      };

      # --- 1b. RASPBERRY PI 4 (NixOS, network appliance) ---
      # Headless DNS/vault/VPN box (see ~/projects/homelab-network). No
      # home-manager: nothing interactive runs here, and less machinery on
      # the box that owns household DNS means less to break.
      nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = piModules;
      };

      # Bootable, headless SD image built FROM the pi config above — SSH and
      # your authorized key are already baked in, so first boot needs no
      # monitor or keyboard: plug in Ethernet, find the Pi's DHCP lease, then
      # `ssh home@<pi-ip>`. Build with `nix build .#images.pi` (requires the
      # aarch64 emulation enabled in hosts/nixos/configuration.nix). Output
      # lands at ./result/sd-image/*.img.zst.
      images.pi =
        (nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = piModules ++ [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ];
        }).config.system.build.sdImage;

      # --- 2. MACBOOK (Intel) ---
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
    };
}
