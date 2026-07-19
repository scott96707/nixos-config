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
    # `vim` is neovim here via vimAlias in modules/common/neovim.nix. Set
    # explicitly because that module's defaultEditor is off — see the comment
    # there for why.
    EDITOR = "vim";
    VISUAL = "vim";
    BROWSER = "firefox";
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    MOZ_ENABLE_WAYLAND = "1";
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

  # Homelab reminder: homelab-network (AdGuard/Caddy, ~/projects/homelab-network)
  # autostarts via systemd at boot — interim home until the Pi takes over
  # DNS. media-server moved to the dp21 host. Surface status on every new
  # shell so a boot-time failure doesn't go unnoticed.
  programs.zsh.initContent = ''
    for svc in homelab-network; do
      state=$(systemctl is-active "$svc" 2>/dev/null)
      if [[ "$state" == "active" ]]; then
        echo -e "\e[32m✓\e[0m $svc"
      else
        echo -e "\e[31m✗\e[0m $svc ($state) — systemctl status $svc"
      fi
    done
  '';

  # Disable Gnome donation reminder
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/housekeeping" = {
      donation-reminder-enabled = false;
    };
  };

  home.shellAliases = {
    fix-mule = "sudo umount -l /drives/mule && sudo ntfsfix -d /dev/disk/by-uuid/F81EE57C1EE533F2";
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
