{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

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
    # "vim" not "nvim": modules/common/neovim.nix sets vimAlias, so `vim` IS
    # neovim here — same binary, same config. Using the vim name uniformly
    # means the appliances (real vim, no neovim) and the workstations share
    # one editor setting.
    home.sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
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
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "Rectangle"
        ];
        RunAtLoad = true;
        KeepAlive = false; # Don't restart it if I quit it manually
        ProcessType = "Interactive";
      };
    };

    # SOPS configuration
    # Scaffolding only — git-name/git-email moved out to
    # modules/common/git-identity.nix, and no other secret is defined here
    # yet. With zero secrets sops-nix is inert, so the age key below need not
    # exist until something actually needs decrypting.
    sops = {
      defaultSopsFile = ./../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";

      age.keyFile = "/Users/${config.myHome.username}/.config/sops/age/keys.txt";
    };
  };
}
