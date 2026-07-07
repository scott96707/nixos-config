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
          ms-toolsai.jupyter
          catppuccin.catppuccin-vsc
          davidanson.vscode-markdownlint
          dracula-theme.theme-dracula
          github.github-vscode-theme
          github.vscode-github-actions
          hashicorp.terraform
          ms-kubernetes-tools.vscode-kubernetes-tools
          ms-python.debugpy
          ms-python.python
          ms-python.vscode-pylance
          oderwat.indent-rainbow
          pkief.material-icon-theme
          redhat.vscode-yaml
          shd101wyy.markdown-preview-enhanced
          tamasfe.even-better-toml
          tim-koehler.helm-intellisense
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
            name = "claude-code";
            publisher = "anthropic";
            version = "2.1.202";
            sha256 = "sha256-gtHPurMqM93UhE6VfqR8y/XiF0nICkrPxwlV+ca7Bd4=";
          }
          {
            name = "pdf";
            publisher = "tomoki1207";
            version = "1.2.2";
            sha256 = "sha256-i3Rlizbw4RtPkiEsodRJEB3AUzoqI95ohyqZ0ksROps=";
          }
          {
            name = "shades-of-purple";
            publisher = "ahmadawais";
            version = "7.3.6";
            sha256 = "sha256-22ZywGew1Qh4YPi51JWTNQLKuz/nzx/iprUK96DQfYU=";
          }
          {
            name = "hcl-lsp";
            publisher = "bahramjoharshamshiri";
            version = "0.2.5";
            sha256 = "sha256-38uZ4TE69voqDuwzAmvcfZ9pQiyroiBNkx8ymygaHww=";
          }
          {
            name = "copilot-theme";
            publisher = "benjaminbenais";
            version = "1.1.0";
            sha256 = "sha256-6uBNlPQOGDmrnnW+sxYP0Int5kyjdPc2gJw61uQAQD8=";
          }
          {
            name = "insert-unicode";
            publisher = "brunnerh";
            version = "0.15.1";
            sha256 = "sha256-RHsq7JmlC+4zGSbDdovCZpjpSW+DvcmYnuz9f6F/N4g=";
          }
          {
            name = "rewrap-revived";
            publisher = "dnut";
            version = "17.10.0";
            sha256 = "sha256-lfQsX27n7BCaM/z5rzRvGzTnbyg+C9YiAgHAnHdtHDo=";
          }
          {
            name = "fontawesome-autocomplete";
            publisher = "janne252";
            version = "1.3.2";
            sha256 = "sha256-tG5IiYzwJkA1xwR5U0I/mdkxx5ioYgXTv9aLnmbSspI=";
          }
          {
            name = "vscode-python-envs";
            publisher = "ms-python";
            version = "1.37.2026070201";
            sha256 = "sha256-WHL0qIXMk+jEhvpEFl/Ljs5X/poPwkcQgxaUfxd54lg=";
          }
          {
            name = "github-actions-vscode";
            publisher = "omartawfik";
            version = "2.7.0";
            sha256 = "sha256-78yBMgIaG2eTCQRGlAEqpO08jCreohT7RDSzLDghMDs=";
          }
          {
            name = "synthwave-vscode";
            publisher = "robbowen";
            version = "0.1.20";
            sha256 = "sha256-J8igs+SQn967OK0PLNZtV9IOJRqwd+q9vmZ+p9eKSoU=";
          }
          {
            name = "material-palenight-theme";
            publisher = "whizkydee";
            version = "2.0.4";
            sha256 = "sha256-FpYqzzeLLVRhClMiMxusBXwTaJnqZbmneRnFTkV9nm8=";
          }
        ];

      keybindings = [
        {
          key = "shift+cmd+0";
          command = "editor.action.detectIndentation";
        }
        {
          key = "shift+cmd+9";
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

        # ── Chat / Copilot ───────────────────────────────────────────────────
        "chat.autopilot.advanced.enabled" = true;
        "chat.editor.fontFamily" = "JetBrainsMono Nerd Font";
        "chat.editor.fontSize" = 13;
        "chat.editor.wordWrap" = "on";
        "chat.fontFamily" = "'New York', 'JetBrainsMono Nerd Font'";
        "chat.fontSize" = 12.5;
        "chat.mcp.gallery.enabled" = true;
        "chat.sessionSync.enabled" = true;
        "chat.tools.terminal.autoApprove" = {
          "git mv" = true;
          "kubectl logs" = true;
          "kubie" = true;
          "mv" = true;
          "terraform" = false;
        };
        "chat.tools.urls.autoApprove" = {
          "https://code.visualstudio.com" = true;
          "https://github.com/microsoft/vscode/wiki/*" = true;
          "https://*.microsoft.com" = true;
          "https://*.terraform.io" = true;
          "https://developer.hashicorp.com" = true;
          "https://github.com" = true;
          "https://github.com/github" = true;
          "https://github.com/github/feedback" = true;
          "https://github.com/github/feedback/discussions" = true;
          "https://github.com/microsoft" = true;
          "https://github.com/microsoft/vscode-copilot-chat" = true;
          "https://github.com/microsoft/vscode-copilot-chat/issues" = true;
          "https://grafana.com" = true;
          "https://grafana.com/docs" = true;
          "https://grafana.com/docs/grafana" = true;
          "https://grafana.com/docs/grafana/latest" = true;
          "https://grafana.com/docs/grafana/latest/setup-grafana" = true;
          "https://grafana.com/docs/grafana/latest/setup-grafana/configure-security" = true;
          "https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication" =
            true;
          "https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/azuread" =
            true;
          "https://learn.microsoft.com" = true;
          "https://learn.microsoft.com/en-us" = true;
          "https://learn.microsoft.com/en-us/entra" = true;
          "https://learn.microsoft.com/en-us/entra/identity-platform" = true;
          "https://learn.microsoft.com/en-us/entra/identity-platform/optional-claims" = true;
          "https://learn.microsoft.com/en-us/entra/identity/hybrid" = true;
          "https://learn.microsoft.com/en-us/entra/identity/hybrid/connect" = true;
          "https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-fed-group-claims" =
            true;
          "https://projectsveltos.github.io" = {
            "approveRequest" = true;
            "approveResponse" = false;
          };
          "https://projectsveltos.io" = {
            "approveRequest" = true;
            "approveResponse" = false;
          };
          "https://*.atlassian.com" = true;
        };
        "chat.viewSessions.orientation" = "stacked";

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
          "**/templates/*.tpl" = "helm";
          "**/templates/*.yaml" = "helm";
          "*.gotmpl" = "helm";
          "*.hcl" = "terraform";
          "*.tf.*" = "terraform";
          "*.yaml" = "helm";
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
          "**/charts/**/charts/**" = true;
        };

        # ── GitHub / GitLens ──────────────────────────────────────────────────
        "github.copilot.chat.codeGeneration.useInstructionFiles" = true;
        "github.copilot.enable" = {
          "*" = true;
          "markdown" = true;
          "plaintext" = false;
          "scminput" = false;
        };
        "github.copilot.nextEditSuggestions.enabled" = true;

        # ── Markdown preview ──────────────────────────────────────────────────
        "markdown-preview-enhanced.enablePreviewZenMode" = false;

        # ── Icons / theme ─────────────────────────────────────────────────────
        "material-icon-theme.activeIconPack" = "react";

        # ── Nix ───────────────────────────────────────────────────────────────
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

        # ── Telemetry ─────────────────────────────────────────────────────────
        "redhat.telemetry.enabled" = false;

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

        # ── Kubernetes ────────────────────────────────────────────────────────
        "vs-kubernetes" = {
          "vs-kubernetes.crd-code-completion" = "disabled";
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
