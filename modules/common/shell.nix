{ ... }:
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
    # Custom settings for Starship
    settings = {
      add_newline = false;
      format = "$username$hostname$directory$git_branch$git_status$nix_shell$python$cmd_duration$character";

      directory = {
        style = "bold blue";
      };

      hostname = {
        ssh_only = false;
        format = "@[$hostname]($style) ";
        style = "bold magenta";
      };

      python = {
        format = "via [🐍 $version]($style) ";
      };

      # Only flag commands that actually took a while.
      cmd_duration = {
        min_time = 3000;
      };
    };
  };
}
