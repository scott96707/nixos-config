{
  # Clear-text, local override for this machine's username.
  # Replace the placeholder with your actual macOS short username.
  #
  # This file is tracked in git (Nix flakes can't see untracked/gitignored
  # files even if they exist on disk), so after editing it, tell git to stop
  # showing it as locally modified:
  #   git update-index --skip-worktree hosts/macbook-arm/local.nix
  # To undo: git update-index --no-skip-worktree hosts/macbook-arm/local.nix
  username = "your_username_here";
}
