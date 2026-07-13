{ lib, ... }:
{
  programs.zsh = {
    enable = true;
    initContent = ''
      # Fix Delete Key (Forward Delete - ^[[3~) prints '~'
      bindkey "^[[3~" delete-char

      # Fix Home/End keys (often broken on Mac/WezTerm)
      bindkey "^[[1~" beginning-of-line
      bindkey "^[[4~" end-of-line
      # Disable bell
      setopt NO_BEEP
      unsetopt BEEP

      eval "$(direnv hook zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    # Official catppuccin-powerline preset (matches wezterm's Catppuccin
    # Mocha; needs a Nerd Font). Regenerate the base file with:
    #   starship preset catppuccin-powerline -o starship-catppuccin-powerline.toml
    # Local tweaks are merged on top below.
    settings = lib.recursiveUpdate (fromTOML (builtins.readFile ./starship-catppuccin-powerline.toml)) {
      add_newline = false;

      # The preset's format, plus $hostname in the red segment,
      # $nix_shell in the green one, and $docker_context (which the
      # preset styles but forgets to render).
      # No $os badge: its default NixOS symbol is the same snowflake the
      # nix_shell segment uses, and $hostname already identifies the
      # machine. Keeps ❄ meaning "inside a nix shell" only.
      format = lib.concatStrings [
        "[](red)"
        "$username"
        "$hostname"
        "[](bg:peach fg:red)"
        "$directory"
        "[](bg:yellow fg:peach)"
        "$git_branch"
        "$git_status"
        "[](fg:yellow bg:green)"
        "$nix_shell"
        "$c"
        "$rust"
        "$golang"
        "$nodejs"
        "$bun"
        "$php"
        "$java"
        "$kotlin"
        "$haskell"
        "$python"
        "[](fg:green bg:sapphire)"
        "$docker_context"
        "$conda"
        "[](fg:sapphire bg:lavender)"
        "$time"
        "[ ](fg:lavender)"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      # Always show which machine this is, like the old prompt did.
      hostname = {
        ssh_only = false;
        style = "bg:red fg:crust";
        format = "[@$hostname ]($style)";
      };

      # Flag nix develop / nix-shell sessions.
      nix_shell = {
        style = "bg:green";
        format = "[[ ❄ $state( ($name)) ](fg:crust bg:green)]($style)";
      };

      # Only flag commands that actually took a while.
      cmd_duration.min_time = 3000;
    };
  };
}
