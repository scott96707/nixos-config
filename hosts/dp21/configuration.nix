{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/common.nix
  ];

  # --- HARDWARE (MSI PRO DP21 13M-1242US, Micro Center) ---
  # CPU:   Intel Core i5-14400 (Raptor Lake Refresh, 10C/16T = 6P+4E,
  #        up to 4.7GHz, 65W desktop part)
  # iGPU:  Intel UHD Graphics 730 (Xe, 24 EU) — QuickSync: H.264/HEVC/VP9
  #        encode+decode, AV1 decode only (no AV1 encode)
  # RAM:   16GB DDR5
  # Disk:  500GB NVMe SSD (media lives here until it fills — see media-server)
  # Net:   1GbE RJ45 (wired to the Xfinity gateway; NOT 2.5G on this model)
  #        + WiFi (Intel AX201/AX211 depending on SKU)
  # Video: HDMI 2.0 (4K60) + DisplayPort 1.4 — future Moonlight client
  #        for the TV. 2.3L SFF case.

  # --- BOOT ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- GPU (QuickSync) ---
  # The Jellyfin container ships its own userspace driver; the host only
  # needs the i915 kernel driver plus its firmware (GuC/HuC) for QSV.
  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;

  # --- MEDIA SERVER ---
  # Module comes from the media-server flake input (~/projects/media-server);
  # it manages podman, firewall ports and autostart. Runbook for the
  # desktop→M3 migration: that repo's README.
  services.media-server = {
    enable = true;
    # dataDriveUuid stays at its null default: media lives on the internal
    # SSD (DATA_ROOT in .env points there). When the SSD fills, the old HDD
    # goes into a USB enclosure and its UUID goes here.
    composeFiles = [
      "docker-compose.yml"
      "docker-compose.gpu.yml" # Intel QSV transcoding
    ];
  };

  # --- MONITORING (homelab-network flake input) ---
  # This box runs the Prometheus server (RAM to spare); the Pi is scrape-
  # target-only. Grafana Cloud free tier via monitoring.server.remoteWrite
  # is the intended dashboard layer — enable once an account + API key
  # exist (needs sops for the passwordFile).
  services.homelab-network.monitoring = {
    nodeExporter.enable = true;
    server = {
      enable = true;
      scrapeTargets = [
        "127.0.0.1:9100" # this host
        # "<pi-ip>:9100" — uncomment once the Pi has its DHCP reservation
      ];
    };
  };

  # --- NETWORKING ---
  networking.hostName = "dp21";
  # Wired-only appliance: default dhcpcd, no NetworkManager. Give it a DHCP
  # reservation on the router — Caddyfile upstreams and clients point here.
  networking.firewall.enable = true;

  # --- STORAGE ---
  services.fstrim.enable = true;
  zramSwap.enable = true;

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
      # MacBook's key (~/.ssh/id_ed25519.pub) — day-to-day admin from the
      # laptop.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxSOei5KWJCu5Fp0C0k1JT+KdwTCXIVDYxQif88/UFL scott96707@gmail.com"
    ];
  };

  # --- HOST SPECIFIC PACKAGES ---
  environment.systemPackages = with pkgs; [
    vim
  ];

  programs.zsh.enable = true;
  # No home-manager on this host, so the desktop's `rebuild`/`cleanup`
  # aliases don't exist here — define them system-wide. With no #attr,
  # nixos-rebuild defaults to this host's hostname (dp21).
  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    cleanup = "sudo nix-collect-garbage -d";
  };

  system.stateVersion = "26.05";
}
