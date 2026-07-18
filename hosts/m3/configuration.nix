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

  # --- HARDWARE (GMKtec NucBox M3, Micro Center) ---
  # CPU:   Intel Core i5-12450H (Alder Lake, 8C/12T = 4P+4E, up to 4.4GHz)
  # iGPU:  Intel UHD Graphics (Xe, 48 EU) — QuickSync: H.264/HEVC/VP9
  #        encode+decode, AV1 decode only (no AV1 encode)
  # RAM:   16GB DDR4-3200 (2x8GB, dual channel)
  # Disk:  1TB NVMe SSD (media lives here until it fills — see media-server)
  # Net:   2.5GbE RJ45 (wired to the Xfinity gateway) + WiFi 6
  # Video: HDMI 2.0 (4K60) — future Moonlight client for the TV

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
  networking.hostName = "m3";
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
    ];
  };

  programs.zsh.enable = true;

  system.stateVersion = "26.05";
}
