{ config, pkgs, ... }:

{
  home.username = "home";
  home.homeDirectory = "/home/home";
  # Leave stateVersion alone. It is auto generated and determines
  # file structure format.
  home.stateVersion = "24.11";

  # Shared Modules
  imports = [
    ./../../modules/nixos/firefox.nix
    ./../../modules/nixos/git.nix
    ./../../modules/common/neovim.nix
    ./../../modules/common/shell.nix
    ./../../modules/common/vscode.nix
    ./../../modules/common/wezterm.nix
  ];

  home.sessionVariables = {
    VISUAL = "nvim";
    BROWSER = "firefox";
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  home.packages = with pkgs; [
    age
    direnv
    nix-direnv
    gcc
    godot_4
    iptables
    libreoffice
    lsof
    mpv
    sops
    tcpdump
    transmission_4-qt
    vlc
    wl-clipboard 
    yt-dlp
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

  # Disable Gnome donation reminder
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/housekeeping" = {
      donation-reminder-enabled = false;
    };
  };

  home.shellAliases = {
    fix-mule="sudo umount -l /drives/mule && sudo ntfsfix -d /dev/disk/by-uuid/F81EE57C1EE533F2";
    rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config/#nixos";
    cleanup = "sudo nix-collect-garbage -d"; 
    sunvim = "sudo -E nvim"; 
    pbcopy = "wl-copy";
    pbpaste = "wl-paste";
  };

  programs.readline = {
    enable = true;
    extraConfig = ''
      # Disable the weird characters during paste
      set enable-bracketed-paste off
      # Readline is how bash terminal handles
      # character inputs
      '';
  };

  programs.home-manager.enable = true;
}
