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

    # Restic → Backblaze B2 (S3-compatible), bucket home-vaultwarden-backup in
    # the us-west-004 region. Client-side encrypted with restic-password; the
    # B2 keyID/appKey live in restic-environment (AWS_ACCESS_KEY_ID /
    # AWS_SECRET_ACCESS_KEY). Both come from sops (see secrets block below).
    # Plain private bucket — no Object Lock (it breaks `restic forget --prune`)
    # and no server-side encryption (restic already encrypts client-side).
    backups = {
      enable = true;
      repository = "s3:s3.us-west-004.backblazeb2.com/home-vaultwarden-backup";
      passwordFile = config.sops.secrets.restic-password.path;
      environmentFile = config.sops.secrets.restic-environment.path;
    };
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

  # Tailscale: reach the whole LAN and get AdGuard DNS from anywhere, with no
  # port-forwarding on the XB8 (Tailscale does its own NAT traversal). This box
  # is the subnet router for the LAN. After this rebuild, authenticate once on
  # the Pi:
  #   sudo tailscale up --advertise-routes=10.0.0.0/24 --accept-dns=false
  # (add --advertise-exit-node to also route all client traffic through home).
  # --accept-dns=false keeps the Pi on its own pinned upstreams. Then in the
  # admin console (login.tailscale.com): approve the 10.0.0.0/24 route and set
  # tailnet DNS nameserver to 10.0.0.200 (AdGuard) so every device filters.
  # useRoutingFeatures = "server" turns on the IP forwarding a subnet router /
  # exit node needs.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };
  # Trust the tailnet interface so subnet-routed peer traffic isn't firewalled.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Tailscale subnet routing forwards LAN traffic faster with UDP GRO
  # forwarding enabled on the NIC — this clears the "UDP GRO forwarding is
  # suboptimally configured" warning from `tailscale up`. Apply the ethtool
  # tweak Tailscale recommends at boot, auto-detecting the default-route
  # interface (so it survives an end0 rename). Purely a throughput
  # optimization; subnet routing works without it.
  systemd.services.tailscale-udp-gro = {
    description = "Enable UDP GRO forwarding on the LAN NIC for Tailscale subnet routing";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      pkgs.ethtool
      pkgs.iproute2
      pkgs.gnugrep
      pkgs.gawk
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      dev=$(ip -o route get 8.8.8.8 | grep -oE 'dev [^ ]+' | awk '{print $2}')
      if [ -n "$dev" ]; then
        ethtool -K "$dev" rx-udp-gro-forwarding on rx-gro-list off
      fi
    '';
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

  programs.zsh.enable = true;
  # No home-manager on this host, so the desktop's `rebuild`/`cleanup`
  # aliases don't exist here — define them system-wide. With no #attr,
  # nixos-rebuild defaults to this host's hostname (pi).
  programs.zsh.shellAliases = {
    rebuild = "nixos-rebuild switch --flake ~/nixos-config --sudo";
    cleanup = "sudo nix-collect-garbage -d";
  };

  # --- NIX (remote deploys from the desktop) ---
  # `nixos-rebuild --flake …#pi --target-host home@<pi>` builds the closure on
  # the desktop and copies it here. The Pi's daemon refuses incoming store
  # paths that aren't signed by a key it trusts — unless the pushing user is
  # trusted — so the copy fails with "lacks a signature by a trusted key".
  # `home` is already a wheel/sudo user (root-equivalent on this box), so
  # trusting it for Nix grants nothing it couldn't already do.
  nix.settings.trusted-users = [ "root" "home" ];

  # Passwordless sudo for wheel. Without a declarative password, `home` was
  # created locked — it could never `sudo`, and with SSH key-only + no console
  # there was no privileged path onto the box at all (fixed by re-flashing with
  # this in place). SSH here is key-only, so the security boundary is the
  # authorized SSH keys, not a sudo password; `home` is the only wheel user.
  # This also lets `nixos-rebuild --target-host home@<pi> --sudo` from the
  # desktop activate non-interactively.
  security.sudo.wheelNeedsPassword = false;

  # --- HOST SPECIFIC PACKAGES ---
  environment.systemPackages = with pkgs; [
    age
    sops
    vim
  ];

  # --- GIT IDENTITY ---
  # System-level (/etc/gitconfig): no home-manager on this appliance either.
  # Less load-bearing than on dp21 — nothing here runs from a checkout — but
  # it makes an in-place `git commit` on nixos-config work rather than fail.
  programs.git = {
    enable = true;
    config = {
      user = {
        name = gitIdentity.name;
        email = gitIdentity.email;
        # Same per-host scheme as dp21. NOTE: unlike dp21, this box has no
        # ~/.ssh/id_ed25519 yet — generate one and register its public half on
        # GitHub as Authentication + Signing, or commits here will abort with
        # "unable to start editor"/key-not-found rather than fall back.
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      core.editor = "vim";
    };
  };

  # --- DEFAULT EDITOR ---
  # Same as dp21: no home-manager, so EDITOR was unset and tools fell back to
  # nano. Real vim here, not the neovim alias the workstations get.
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  # --- SECRETS (sops-nix) ---
  # The Pi needs its own age key at /var/lib/sops-nix/key.txt (generate with
  # `age-keygen`), and that key's PUBLIC half added to .sops.yaml followed by
  # `sops updatekeys secrets/secrets.yaml` — otherwise nothing here decrypts.
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Uncomment as the corresponding entries are added to secrets.yaml:
    secrets = {
      # vaultwarden-env = { };
      # wireguard-private-key = { };
      restic-password = { };
      restic-environment = { };
    };
  };

  system.stateVersion = "26.05";
}
