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
      rclone
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

    # Google Drive configuration
    sops.secrets.rclone_config = { }; # Expects 'rclone_config' in secrets.yaml

    # This tells sops to write the file to ~/.config/rclone/rclone.conf
    sops.templates."rclone.conf" = {
      content = config.sops.placeholder.rclone_config;
      path = "${config.xdg.configHome}/rclone/rclone.conf";
    };

    launchd.agents.google-drive-mount = {
      enable = true;
      config = {
        Label = "org.nix-community.rclone-mount";
        # Keep the PATH environment
        EnvironmentVariables = {
          PATH = "${pkgs.rclone}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };

        ProgramArguments = [
          "${pkgs.rclone}/bin/rclone"
          "serve"
          "webdav"
          "secret:"
          "--addr=127.0.0.1:8080"
          "--config=${config.xdg.configHome}/rclone/rclone.conf"
          "--vfs-cache-mode=full"
          "--exclude=.DS_Store" # Stop trying to upload Mac metadata
          "--vfs-read-chunk-size=32M" # Improve streaming stability
          "--dir-cache-time=10s" # Refresh file list faster
        ];

        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/rclone.out";
        StandardErrorPath = "/tmp/rclone.err";
      };
    };
  };
}
