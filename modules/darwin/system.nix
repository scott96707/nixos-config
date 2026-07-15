{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.myDarwin = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary macOS user account for this host.";
    };
    extraCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew casks to install in addition to the shared set.";
    };
  };

  config =
    let
      username = config.myDarwin.username;
    in
    {
      # --- System Identity ---
      system.primaryUser = username;

      users.users.${username} = {
        name = username;
        home = "/Users/${username}";
      };

      # --- System Packages ---
      environment.systemPackages = with pkgs; [
        mkalias
        coreutils
        nixd
      ];

      nix.settings = {
        # Change Nix download buffer size. I was getting errors about this.
        # Increase to 268435456 (256MB) if this is still too small.
        download-buffer-size = 134217728; # 128 MB
        # Allow Nix to run a build job for each of the computer's cores.
        max-jobs = "auto";
        # Remove limit on how many CPU cores each individual build job can use.
        cores = 0;
      };

      # Script to pickup apps Nix installs and place them in /Applications/Nix so that they're easy to find
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
          # We iterate over the symlinks, resolve them to real paths using coreutils, and alias them.
          for app in "${env}/Applications/"*; do
            if [ -e "$app" ]; then
              app_name=$(basename "$app")
              # Resolve the real path so mkalias points to the actual binary, not a symlink
              real_path=$(${pkgs.coreutils}/bin/readlink -f "$app")

              echo "Linking $app_name -> $real_path" >&2
              ${pkgs.mkalias}/bin/mkalias "$real_path" "/Applications/Nix Apps/$app_name"
            fi
          done

          # 3. Link Home Manager Packages
          HM_APPS="/Users/${username}/Applications/Home Manager Apps"

          if [ -d "$HM_APPS" ]; then
            for app in "$HM_APPS/"*; do
              if [ -e "$app" ]; then
                app_name=$(basename "$app")
                # Only alias if it doesn't already exist
                if [ ! -e "/Applications/Nix Apps/$app_name" ]; then
                  real_path=$(${pkgs.coreutils}/bin/readlink -f "$app")
                  echo "Linking HM App: $app_name -> $real_path" >&2
                  ${pkgs.mkalias}/bin/mkalias "$real_path" "/Applications/Nix Apps/$app_name"
                fi
              fi
            done
          fi
        '';

      # Must install homebrew manually on MacOS before using and modules:
      # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      homebrew = {
        enable = true;

        onActivation.cleanup = "zap"; # Uninstalls apps not in this list
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;

        casks = [
          # Firefox cannot be managed through Nix. If you try, it will overwrite your Firefox profile every time you rebuild
          "firefox"
          "macfuse"
          "rectangle"
        ]
        ++ config.myDarwin.extraCasks;
      };

      # --- macOS Defaults ---
      system.defaults = {

        # Control the Dock
        dock = {
          autohide = true;
          show-recents = false; # Clean up the dock
          mru-spaces = false; # Stop macOS from rearranging your Spaces/Desktops
          orientation = "bottom";
          tilesize = 64;
        };

        # Mission Control Settings
        spaces.spans-displays = false; # false = "Displays have separate Spaces" is ON

        # Control Finder
        finder = {
          AppleShowAllExtensions = true;
          _FXShowPosixPathInTitle = true; # Show full path in Finder title bar
          FXEnableExtensionChangeWarning = false; # Stop annoying "Are you sure you want to change extension"
          ShowPathbar = true;
          ShowStatusBar = true;
        };

        CustomUserPreferences = {
          "com.apple.controlcenter" = {
            "NSStatusItem Visible Weather" = true;
          };
        };
        # General UI/UX
        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          InitialKeyRepeat = 15; # Fast key repeat (essential for Vim users)

          # Set to false to show the menu bar at all times
          # Set to true if you ever want it to autohide
          _HIHideMenuBar = false;
          KeyRepeat = 2; # Fast key repeat
          "com.apple.mouse.tapBehavior" = 1; # Enable tap-to-click
          AppleInterfaceStyle = "Dark"; # Force Dark Mode
        };

        # Login and Security
        loginwindow.GuestEnabled = false;
      };

      # --- Nix Core Settings ---
      nixpkgs.config.allowUnfree = true;

      ids.gids.nixbld = 350;

      # Disable Nix management of Touch ID to avoid the /etc/pam.d symlink error
      security.pam.services.sudo_local.touchIdAuth = false;

      security.sudo.extraConfig = ''
        # Allow ${username} to run darwin-rebuild without a password
        ${username} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
        # Also allow the underlying nix-build command if needed
        ${username} ALL=(ALL) NOPASSWD: /nix/var/nix/profiles/default/bin/nix-build
      '';

      system.stateVersion = 4;
    };
}
