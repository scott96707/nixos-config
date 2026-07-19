{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/common/common.nix
  ];

  # --- BOOT (Raspberry Pi 4, NixOS aarch64 sd-image) ---
  # The sd-image boots via the Pi firmware + extlinux, not GRUB/systemd-boot.
  # No hardware-configuration.nix: the sd-image has a fixed layout, declared
  # inline below.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  hardware.enableRedistributableFirmware = true;

  # --- HOMELAB NETWORK (DNS + reverse proxy + vault + VPN) ---
  # Module comes from the homelab-network flake input
  # (~/projects/homelab-network). Before the first rebuild on the Pi, that
  # repo must also be cloned to /home/home/projects/homelab-network — the
  # compose stack runs from a writable checkout (see its README "Pi
  # bring-up" section).
  services.homelab-network = {
    enable = true;

    # 2GB Pi: compressed-in-RAM swap absorbs nixos-rebuild memory spikes
    # without wearing the SD card.
    zramSwap.enable = true;

    # Works without an admin token (admin panel disabled until one is
    # provided). To enable it: add vaultwarden-env to secrets/secrets.yaml
    # (content: ADMIN_TOKEN=<openssl rand -base64 48>), then uncomment.
    vaultwarden = {
      enable = true;
      # environmentFile = config.sops.secrets.vaultwarden-env.path;
    };

    # Scrape target only; the Prometheus server lives on the mini PC.
    monitoring.nodeExporter.enable = true;

    # Blocked on secrets that don't exist yet. To enable: `wg genkey` →
    # wireguard-private-key in secrets/secrets.yaml, `wg pubkey` on each
    # device for the peer list, then uncomment and forward UDP 51820 to
    # this host on the gateway.
    # wireguard = {
    #   enable = true;
    #   privateKeyFile = config.sops.secrets.wireguard-private-key.path;
    #   peers = [
    #     {
    #       name = "phone";
    #       publicKey = "<pubkey>";
    #       allowedIPs = [ "10.100.0.2/32" ];
    #     }
    #   ];
    # };

    # Blocked on Backblaze B2 / Cloudflare R2 credentials. To enable: add
    # restic-password + restic-environment to secrets/secrets.yaml, then
    # uncomment.
    # backups = {
    #   enable = true;
    #   repository = "s3:<endpoint>/<bucket>";
    #   passwordFile = config.sops.secrets.restic-password.path;
    #   environmentFile = config.sops.secrets.restic-environment.path;
    # };
  };

  # This machine is the LAN's DNS server: the router's DHCP hands out this
  # host's own IP as DNS. Pin real upstreams for the host itself so boot
  # can't deadlock (image pulls need DNS before AdGuard is up). Same
  # reasoning as on the desktop during Phase 1.
  networking.nameservers = [
    "9.9.9.9"
    "1.1.1.1"
  ];

  # --- NETWORKING ---
  networking.hostName = "pi";
  # Wired-only appliance: default dhcpcd, no NetworkManager. Give the Pi a
  # DHCP reservation on the router — the AdGuard wildcard rewrite and the
  # router's DNS setting both point at this IP.
  networking.firewall.enable = true;

  # --- REMOTE ACCESS ---
  # Headless box: SSH is the only way in after first boot.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # --- USERS ---
  users.users.home = {
    isNormalUser = true;
    description = "home";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # NixOS desktop's key (~/.ssh/id_ed25519.pub) — the machine rebuilds
      # are pushed from.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYmkZ6qbZ6ACFeQRm2Pts2ofM/Zk42GUu1bYOcPkmDo scott96707@gmail.com"
    ];
  };

  programs.zsh.enable = true;
  # No home-manager on this host, so the desktop's `rebuild`/`cleanup`
  # aliases don't exist here — define them system-wide. With no #attr,
  # nixos-rebuild defaults to this host's hostname (pi).
  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    cleanup = "sudo nix-collect-garbage -d";
  };

  # --- HOST SPECIFIC PACKAGES ---
  environment.systemPackages = with pkgs; [
    age
    sops
    vim
  ];

  # --- SECRETS (sops-nix) ---
  # The Pi needs its own age key at /var/lib/sops-nix/key.txt (generate with
  # `age-keygen`), and that key's PUBLIC half added to .sops.yaml followed by
  # `sops updatekeys secrets/secrets.yaml` — otherwise nothing here decrypts.
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Uncomment as the corresponding entries are added to secrets.yaml:
    # secrets = {
    #   vaultwarden-env = { };
    #   wireguard-private-key = { };
    #   restic-password = { };
    #   restic-environment = { };
    # };
  };

  system.stateVersion = "26.05";
}
