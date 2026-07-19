{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  gitIdentity = import ../../modules/common/git-identity.nix;
in
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

  # --- MANGA AGGREGATOR ---
  # Module comes from the manga-aggregator flake input
  # (~/projects/manga-aggregator); Flask app on :5050, systemd-managed.
  # Needs a writable checkout at /home/home/projects/manga-aggregator with
  # credentials.json + manga_reader.db in place (both gitignored — copy
  # from wherever it last ran). FlareSolverr comes from the media-server
  # stack on this same host (localhost:8191).
  services.manga-aggregator.enable = true;

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

  # VS Code Remote-SSH downloads a generic prebuilt server into
  # ~/.vscode-server on first connect; that binary is linked against the FHS
  # loader (/lib64/ld-linux-x86-64.so.2), which NixOS doesn't ship. nix-ld
  # supplies it. Without this the client retries the handshake forever.
  # Edits land in the ~/projects checkouts, which the manga-aggregator and
  # media-server units run from directly (see their WorkingDirectory) — so
  # they take effect on unit restart, not on rebuild. Changes to *those
  # repos' nix modules* still need a push + `nix flake update` here.
  programs.nix-ld.enable = true;

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

  # --- GIT IDENTITY ---
  # System-level (/etc/gitconfig) rather than home-manager: this box has no
  # home-manager, and commits do get made here — the ~/projects checkouts are
  # what the manga-aggregator and media-server units actually run from. Without
  # this, `git commit` on dp21 fails outright or invents an identity from the
  # hostname.
  programs.git = {
    enable = true;
    config = {
      user = {
        name = gitIdentity.name;
        email = gitIdentity.email;
        # Per-host key: this box has its own ~/.ssh/id_ed25519, and its public
        # half is registered on GitHub as BOTH an Authentication and a Signing
        # key. Auth-only registration signs fine but never shows Verified.
        # Tilde (not /home/home) so a shared /etc/gitconfig resolves per-user.
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      core.editor = "vim";
    };
  };

  # --- DEFAULT EDITOR ---
  # No home-manager here, so nothing was setting EDITOR at all: `systemctl
  # edit`, `visudo` and friends fell back to nano. Real vim on this host, not
  # the neovim that `vim` aliases to on the workstations.
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  programs.zsh.enable = true;
  # No home-manager on this host, so the desktop's `rebuild`/`cleanup`
  # aliases don't exist here — define them system-wide. With no #attr,
  # nixos-rebuild defaults to this host's hostname (dp21).
  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    cleanup = "sudo nix-collect-garbage -d";
  };

  # The compose stack runs under the ROOTFUL podman service, but the podman
  # CLI defaults to rootless for a normal user — so `podman ps` in ~/projects/
  # media-server silently lists nothing instead of erroring. CONTAINER_HOST
  # points it at the rootful socket (the media-server module already puts this
  # user in the `podman` group, so no sudo needed).
  #
  # Deliberately NOT set globally: that would hijack every podman invocation
  # on the host. direnv scopes it to the media-server checkout via its .envrc,
  # leaving rootless podman the default everywhere else.
  programs.direnv.enable = true;
  # Whitelist the checkout so its .envrc loads without a manual `direnv allow`.
  # direnv's trust prompt guards against a hostile .envrc arriving via a repo
  # you cloned; this one is our own config, on a host only we log into.
  programs.direnv.settings.whitelist.prefix = [ "/home/home/projects/media-server" ];

  system.stateVersion = "26.05";
}
