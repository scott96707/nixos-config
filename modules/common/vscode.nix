{ config, pkgs, ... }:

let
  # The custom keybindings need cmd on macOS and ctrl on Linux.
  mod = if pkgs.stdenv.isDarwin then "cmd" else "ctrl";
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # Extensions are fully declarative: anything installed through the UI
    # disappears on the next rebuild. Add new extensions here instead.
    mutableExtensionsDir = false;

    profiles.default = {
      # Official Extensions in pkgs.vscode-extensions
      extensions =
        with pkgs.vscode-extensions;
        [
          ms-azuretools.vscode-docker
          ms-toolsai.jupyter
          davidanson.vscode-markdownlint
          github.vscode-github-actions
          hashicorp.terraform
          oderwat.indent-rainbow
          pkief.material-icon-theme
          redhat.vscode-yaml
          shd101wyy.markdown-preview-enhanced
          tamasfe.even-better-toml
        ]
        # Marketplace Extensions not packaged in pkgs.vscode-extensions.
        # Sourced from nix-vscode-extensions, which tracks the VS Code
        # Marketplace directly, so these stay current via `nix flake update`
        # with no manual version/sha256 pins to maintain.
        ++ (with pkgs.vscode-marketplace; [
          jnoortheen.nix-ide
          janisdd.vscode-edit-csv
          anthropic.claude-code
          tomoki1207.pdf
          ahmadawais.shades-of-purple
          bahramjoharshamshiri.hcl-lsp
          brunnerh.insert-unicode
          dnut.rewrap-revived
          janne252.fontawesome-autocomplete
          ms-python.vscode-python-envs
          ms-python.vscode-pylance
          ms-python.debugpy
          ms-python.python
          ms-vscode-remote.remote-ssh
        ]);

      keybindings = [
        {
          key = "shift+${mod}+0";
          command = "editor.action.detectIndentation";
        }
        {
          key = "shift+${mod}+9";
          command = "editor.action.indentationToSpaces";
        }
      ];

      userSettings = {
        # ── Language-specific overrides ─────────────────────────────────────
        "[markdown]" = {
          # Don't ignore whitespace-only diffs in Markdown
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.formatOnSave" = true;
        };
        "[terraform]" = {
          # Format Terraform files with the official HashiCorp extension on save
          "editor.defaultFormatter" = "hashicorp.terraform";
          "editor.formatOnSave" = true;
        };
        "[terraform-vars]" = {
          # Same formatter rules for *.tfvars files
          "editor.defaultFormatter" = "hashicorp.terraform";
          "editor.formatOnSave" = true;
        };

        # ── Editors / diff ───────────────────────────────────────────────────
        "diffEditor.ignoreTrimWhitespace" = false;
        "diffEditor.wordWrap" = "on";
        "editor.cursorBlinking" = "smooth";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.minimap.enabled" = false;
        "editor.rulers" = [
          80
          120
        ];
        "editor.smoothScrolling" = true;
        "editor.stickyScroll.enabled" = true;
        "editor.wordWrap" = "on";

        # ── Explorer ──────────────────────────────────────────────────────────
        "explorer.compactFolders" = false;
        "explorer.confirmDragAndDrop" = false;

        # ── Files ─────────────────────────────────────────────────────────────
        "files.associations" = {
          "*.hcl" = "terraform";
          "*.tf.*" = "terraform";
          "terragrunt.hcl" = "terragrunt";
        };
        "files.autoSave" = "onFocusChange";
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = false;
        "files.trimTrailingWhitespace" = true;
        "files.watcherExclude" = {
          "**/.terraform/**" = true;
          "**/.git/**" = true;
        };
        "search.exclude" = {
          "**/.terraform/**" = true;
          "**/*.tfstate*" = true;
        };

        # ── Markdown preview ──────────────────────────────────────────────────
        "markdown-preview-enhanced.enablePreviewZenMode" = false;

        # ── Icons / theme ─────────────────────────────────────────────────────
        "material-icon-theme.activeIconPack" = "react";

        # ── Nix ───────────────────────────────────────────────────────────────
        # Enable the Nix language server.
        "nix.enableLanguageServer" = true;
        # Set nixfmt as the formatter.
        "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
        "nix.editor.formatOnSave" = true;
        "nix.editor.defaultFormatter" = "jnoortheen.nix-ide";
        # Use nixd for language server features.
        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
        "nix.serverSettings" = {
          "nixd" = {
            # Run nixfmt when formatting.
            "formatting" = {
              "command" = [ "nixfmt" ];
            };
            # Completion + hover docs for NixOS and home-manager options
            # while editing this repo.
            "options" = {
              "nixos" = {
                "expr" =
                  "(builtins.getFlake \"${config.home.homeDirectory}/nixos-config\").nixosConfigurations.nixos.options";
              };
              "home-manager" = {
                "expr" =
                  "(builtins.getFlake \"${config.home.homeDirectory}/nixos-config\").nixosConfigurations.nixos.options.home-manager.users.type.getSubOptions [ ]";
              };
            };
          };
        };

        # ── Telemetry ─────────────────────────────────────────────────────────
        "redhat.telemetry.enabled" = false;

        # ── Updates ───────────────────────────────────────────────────────────
        # VS Code is managed via Nix (pkgs.vscode), so disable its built-in
        # self-updater. Otherwise it repeatedly prompts macOS to install a
        # privileged helper tool to replace the (read-only) Nix store app.
        "update.mode" = "none";
        "extensions.autoUpdate" = false;
        "extensions.autoCheckUpdates" = false;

        # ── Terminal ──────────────────────────────────────────────────────────
        "terminal.integrated.cursorStyle" = "line";
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "terminal.integrated.smoothScrolling" = true;
        # Use zsh as the default terminal profile.
        "terminal.integrated.defaultProfile.linux" = "zsh";
        # Define the zsh profile path and login args.
        "terminal.integrated.profiles.linux" = {
          "zsh" = {
            "path" = "${pkgs.zsh}/bin/zsh";
            "args" = [ "-l" ];
          };
        };

        # ── Window / Workbench ───────────────────────────────────────────────
        "window.newWindowProfile" = "Default";
        "workbench.activityBar.location" = "bottom";
        "workbench.colorCustomizations" = {
          "sideBar.foreground" = "#dadee6";
        };
        "workbench.colorTheme" = "Shades of Purple";
        "workbench.editor.enablePreview" = false;
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.list.smoothScrolling" = true;
        "workbench.sideBar.location" = "right";
        "workbench.tree.indent" = 10;
        "workbench.tree.renderIndentGuides" = "always";
      };
    };
  };
}
