{ config, pkgs, lib, inputs, ... }:

let local = import ./local.nix; in

{
  # Machine-specific identity
  home.username = local.username;
  home.stateVersion = "24.11";

  # Shared Modules
  imports = [
    ./../../modules/macbook/git.nix
    ./../../modules/common/neovim.nix
    ./../../modules/common/shell.nix
    ./../../modules/common/vscode.nix
    ./../../modules/common/iterm2.nix

    inputs.sops-nix.homeManagerModules.sops
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    cleanup = "nix-collect-garbage -d";
    rebuild = "sudo darwin-rebuild switch --flake ~/nixos-config#macbook-arm";
  };

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

  launchd.agents.start-rectangle = {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/open" "-a" "Rectangle" ];
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };

  sops = {
    defaultSopsFile = ./../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/Users/${local.username}/.config/sops/age/keys.txt";

    secrets.git-name = {};
    secrets.git-email = {};

    templates."git-user.conf".content = ''
      [user]
        name = ${config.sops.placeholder.git-name}
        email = ${config.sops.placeholder.git-email}
    '';
  };

  sops.secrets.rclone_config = {};

  sops.templates."rclone.conf" = {
    content = config.sops.placeholder.rclone_config;
    path = "${config.xdg.configHome}/rclone/rclone.conf"; 
  };

  launchd.agents.google-drive-mount = {
    enable = true;
    config = {
      Label = "org.nix-community.rclone-mount";
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
        "--exclude=.DS_Store"
        "--vfs-read-chunk-size=32M"
        "--dir-cache-time=10s"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/rclone.out";
      StandardErrorPath = "/tmp/rclone.err";
    };
  };
}
