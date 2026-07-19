{ pkgs, ... }:

let
  identity = import ../common/git-identity.nix;
in
{
  # 1. Install Delta (The modern diff tool)
  home.packages = [ pkgs.delta ];

  programs.git = {
    enable = true;

    settings = {
      # Identity is plain data now, not a sops template include — see
      # modules/common/git-identity.nix for why.
      user.name = identity.name;
      user.email = identity.email;

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

      # Tell Git to use SSH for signing
      gpg.format = "ssh";

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

    # SSH Signing (Works on both Mac and Linux)
    signing = {
      signByDefault = true;
      key = "~/.ssh/id_ed25519.pub";
    };
  };
}
