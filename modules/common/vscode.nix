{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      # Official Extensions in pkgs.vscode-extensions
      extensions =
        with pkgs.vscode-extensions;
        [
          jnoortheen.nix-ide
          eamodio.gitlens
          ms-azuretools.vscode-docker
          ms-python.python
          ms-toolsai.jupyter
          oderwat.indent-rainbow
        ]
        # Marketplace Extensions not packaged in pkgs.vscode-extensions
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "vscode-edit-csv";
            publisher = "janisdd";
            version = "0.8.2";
            sha256 = "sha256-DbAGQnizAzvpITtPwG4BHflUwBUrmOWCO7hRDOr/YWQ=";
          }
          {
            name = "chatgpt";
            publisher = "openai";
            version = "0.5.56";
            sha256 = "sha256-FAy2Cf2XnOnctBBATloXz8y4cLNHBoXAVnlw42CQzN8=";
          }
          {
            name = "pdf";
            publisher = "tomoki1207";
            version = "1.2.2";
            sha256 = "sha256-i3Rlizbw4RtPkiEsodRJEB3AUzoqI95ohyqZ0ksROps=";
          }
        ];

      userSettings = {
        # Set Chat/Codex chat size
        "chat.fontSize" = 14;
        # Set code editor font size within Chat/Codex
        "chat.editor.fontSize" = 14;
        # Smooth caret animation when moving around the editor.
        "editor.cursorSmoothCaretAnimation" = "on";
        # Keep indentation consistent with the configured tab size.
        "editor.detectIndentation" = false;
        # Base editor font size in points.
        "editor.fontSize" = 14;
        # Format files automatically on save.
        "editor.formatOnSave" = true;
        # Use spaces when pressing Tab.
        "editor.insertSpaces" = true;
        # Hide the minimap to reduce visual noise.
        "editor.minimap.enabled" = false;
        # Show whitespace only for the current selection.
        "editor.renderWhitespace" = "selection";
        "editor.smoothScrolling" = true;
        # Display a tab as 2 spaces.
        "editor.tabSize" = 2;

        "extensions.autoCheckUpdates" = false;

        # Auto-save when switching focus.
        "files.autoSave" = "onFocusChange";
        # Ignore heavy paths for file watching to reduce churn.
        "files.watcherExclude" = {
          "**/.direnv/**" = true;
          "**/.git/objects/**" = true;
          "**/node_modules/**" = true;
          "**/result/**" = true;
        };

        # Keep repos fresh by fetching in the background.
        "git.autofetch" = true;
        # Skip the confirmation prompt when syncing.
        "git.confirmSync" = false;
        # Allow commits without staging all files first.
        "git.enableSmartCommit" = true;

        # Enable the Nix language server.
        "nix.enableLanguageServer" = true;
        # Set nixfmt as the formatter.
        "nix.formatterPath" = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
        "nix.editor.formatOnSave" = true;
        "nix.editor.defaultFormatter" = "jnoortheen.nix-ide";
        # Use nixd for language server features.
        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";

        # Configure nixd to run nixfmt when formatting.
        "nix.serverSettings" = {
          "nixd" = {
            "formatting" = {
              "command" = [ "nixfmt" ];
            };
          };
        };

        # Exclude large build output from global search.
        "search.exclude" = {
          "**/node_modules" = true;
          "**/result" = true;
        };

        # Copy terminal text on selection for quick pastes.
        "terminal.integrated.copyOnSelection" = true;
        # Blink the terminal cursor for visibility.
        "terminal.integrated.cursorBlinking" = true;
        # Use zsh as the default terminal profile.
        "terminal.integrated.defaultProfile.linux" = "zsh";
        # Define the zsh profile path and login args.
        "terminal.integrated.profiles.linux" = {
          "zsh" = {
            "path" = "${pkgs.zsh}/bin/zsh";
            "args" = [ "-l" ];
          };
        };
        # Keep plenty of terminal scrollback.
        "terminal.integrated.scrollback" = 10000;

        # Increase overall UI scaling (affects Chat text too).
        "window.zoomLevel" = 1;

        # Use antialiased fonts for smoother UI text.
        "workbench.fontAliasing" = "antialiased";
        # Disable VSCode profiles and always use the default
        "workbench.profile.enabled" = false;
        # Place the secondary side bar on the right.
        "workbench.secondarySideBar.location" = "right";
        # Keep the main side bar on the left.
        "workbench.sideBar.location" = "left";
        # Slightly increase tree indent for readability.
        "workbench.tree.indent" = 12;
      };
    };
  };
}
