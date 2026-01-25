{ pkgs, config, ... }:

{
  # 1. Install Delta (The modern diff tool)
  home.packages = [ pkgs.delta ];

  programs.git = {
    enable = true;

    includes = [
      { path = config.sops.templates."git-user.conf".path; }
    ];

    settings = {
      aliases = {
        co = "checkout";
        ci = "commit";
        st = "status";
        br = "branch";
        hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
        type = "cat-file -t";
        dump = "cat-file -p";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";

      # --- SSH commit signing (Git "Verified") ---
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = "~/.ssh/id_ed25519.pub"; # points to the PUBLIC key
      # (optional) sign tags too:
      # tag.gpgsign = true;

      # Tell git to use a "Verified badge" on commits
      commit.verbose = true;

      # Delta Configuration
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };

      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };

    # Home Manager convenience mapping (also sets commit.gpgsign + user.signingkey)
    signing = {
      signByDefault = true;
      key = "~/.ssh/id_ed25519.pub";
    };
  };
}
