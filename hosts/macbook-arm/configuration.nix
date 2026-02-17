{ pkgs, config, ... }:
let
  local = import ./local.nix;
in
{

  imports = [
    ./../../modules/common/common.nix
  ];

  # --- System Identity ---
  system.primaryUser = local.username;

  users.users.${local.username} = {
    name = local.username;
    home = "/Users/${local.username}";
  };

  # --- System Packages ---
  environment.systemPackages = with pkgs; [
    mkalias
    coreutils
    nixd
    nixfmt
  ];

  nix.settings = {
    download-buffer-size = 134217728; # 128 MB
    max-jobs = "auto";
    cores = 0;
  };

  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = [ "/Applications" ];
      };
    in
    pkgs.lib.mkForce ''
      # 1. Clean up
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps

      # 2. Link System Packages
      for app in "${env}/Applications/"*; do
        if [ -e "$app" ]; then
          app_name=$(basename "$app")
          real_path=$(${pkgs.coreutils}/bin/readlink -f "$app")
          echo "Linking $app_name -> $real_path" >&2
          ${pkgs.mkalias}/bin/mkalias "$real_path" "/Applications/Nix Apps/$app_name"
        fi
      done

      # 3. Link Home Manager Packages
      HM_APPS="/Users/${local.username}/Applications/Home Manager Apps"

      if [ -d "$HM_APPS" ]; then
        for app in "$HM_APPS/"*; do
          if [ -e "$app" ]; then
            app_name=$(basename "$app")
            if [ ! -e "/Applications/Nix Apps/$app_name" ]; then
              real_path=$(${pkgs.coreutils}/bin/readlink -f "$app")
              echo "Linking HM App: $app_name -> $real_path" >&2
              ${pkgs.mkalias}/bin/mkalias "$real_path" "/Applications/Nix Apps/$app_name"
            fi
          fi
        done
      fi
    '';

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    casks = [
      "firefox"
      "iterm2"
      "macfuse"
      "rectangle"
    ];
  };

  home-manager = {
    backupFileExtension = "backup";
  };

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      orientation = "bottom";
      tilesize = 64;
    };
    spaces.spans-displays = false;
    finder = {
      AppleShowAllExtensions = true;
      _FXShowPosixPathInTitle = true;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    CustomUserPreferences = {
      "com.apple.controlcenter" = {
        "NSStatusItem Visible Weather" = true;
      };
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      _HIHideMenuBar = false;
      KeyRepeat = 2;
      "com.apple.mouse.tapBehavior" = 1;
      AppleInterfaceStyle = "Dark";
    };
    loginwindow.GuestEnabled = false;
  };

  nixpkgs.config.allowUnfree = true;
  nix.optimise.automatic = true;

  ids.gids.nixbld = 350;

  security.pam.services.sudo_local.touchIdAuth = false;

  security.sudo.extraConfig = ''
    # Allow ${local.username} to run darwin-rebuild without a password
    ${local.username} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    ${local.username} ALL=(ALL) NOPASSWD: /nix/var/nix/profiles/default/bin/nix-build
  '';

  system.stateVersion = 4;
}
