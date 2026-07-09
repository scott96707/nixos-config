{ pkgs, ... }: {
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
    # Disable audible bell
    initExtra = ''
    '';
  };

  programs.starship = {
    enable = true;
    # Custom settings for Starship
    settings = {
      add_newline = false;
      format = "$username$hostname$directory$git_branch$python$kubernetes$character";
      
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
    };
  };
}
