{ config, pkgs, lib, inputs, ... }:

{
  options.myHome = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "macOS short username for this host.";
    };
    flakeHost = lib.mkOption {
      type = lib.types.str;
      description = "darwinConfigurations attribute name used by the `rebuild` alias, e.g. \"macbook-intel\".";
    };
  };

  imports = [
    ./../macbook/git.nix
    ./../common/neovim.nix
    ./../common/shell.nix
    ./../common/vscode.nix

    inputs.sops-nix.homeManagerModules.sops
  ];

  config = {
    # Machine-specific identity
    home.username = config.myHome.username;
    home.stateVersion = "24.11";

    # macOS Specific session variables
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # macOS Specific Aliases
    home.shellAliases = {
      cleanup = "nix-collect-garbage -d";
      rebuild = "sudo darwin-rebuild switch --flake ~/nixos-config#${config.myHome.flakeHost}";
    };

    # Packages for the Mac
    home.packages = with pkgs; [
      fd
      htop
      jq
      ripgrep
      tree
    ];

    programs.home-manager.enable = true;
    programs.bash.enable = true;

    # Create a Launch Agent to start Rectangle on login
    launchd.agents.start-rectangle = {
      enable = true;
      config = {
        ProgramArguments = [ "/usr/bin/open" "-a" "Rectangle" ];
        RunAtLoad = true;
        KeepAlive = false; # Don't restart it if I quit it manually
        ProcessType = "Interactive";
      };
    };

    # SOPS configuration
    sops = {
      defaultSopsFile = ./../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";

      age.keyFile = "/Users/${config.myHome.username}/.config/sops/age/keys.txt";

      secrets.git-name = { };
      secrets.git-email = { };

      # This creates the file at ~/.config/sops-nix/secrets/templates/git-user.conf
      templates."git-user.conf".content = ''
        [user]
          name = ${config.sops.placeholder.git-name}
          email = ${config.sops.placeholder.git-email}
      '';
    };
  };
}
