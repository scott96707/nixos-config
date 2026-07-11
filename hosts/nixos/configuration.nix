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

  # --- BOOT & KERNEL ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Filesystems & Drivers
  boot.supportedFilesystems = [
    "ntfs"
    "ntfs3"
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "amdgpu" ];

  # GPU/Display fixes
  boot.kernelParams = [
    "amdgpu.si_support=1"
    "radeon.si_support=0"
    "amdgpu.dc=1"
  ];

  # --- HARDWARE & GPU ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.enableRedistributableFirmware = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.opencl.enable = true;

  # --- AUDIO FIXES (Wireplumber) ---
  environment.etc."wireplumber/main.lua.d/51-hdmi-priority.lua".text = ''
    alsa_monitor.rules = alsa_monitor.rules or {}
    table.insert(alsa_monitor.rules, 1, {
      matches = {
        { { "node.name", "matches", "alsa_output.pci-0000_0c_00.1.hdmi-stereo" } },
      },
      apply_properties = {
        ["priority.session"] = 2000,
      }
    })
  '';

  # --- MEDIA SERVER ---
  # Module comes from the media-server flake input (~/projects/media-server);
  # it manages podman, the /drives/backup mount, firewall ports and autostart.
  services.media-server = {
    enable = true;
    dataDriveUuid = "FEE8A53BE8A4F2D7"; # 1.4TB NTFS "Backup" drive (sda1)
    composeFiles = [
      "docker-compose.yml"
      "docker-compose.gpu.yml" # AMD VAAPI transcoding; not on the future Pi
    ];
  };

  # --- STORAGE & MOUNTS ---
  services.fstrim.enable = true;

  fileSystems."/drives/aming" = {
    device = "/dev/disk/by-uuid/60F8ABD5F8ABA7AC";
    fsType = "ntfs3";
    options = [
      "defaults"
      "nofail"
      "uid=1000"
      "gid=100"
      "noauto" # Don't try to mount at boot
      "x-systemd.automount" # Mount on access
      "x-systemd.idle-timeout=1min" # Unmount after 1 min of inactivity
      "x-systemd.device-timeout=5s" # If the label 'Mule' isn't found in 5s, stop trying
    ];
  };

  fileSystems."/drives/mule" = {
    device = "/dev/disk/by-uuid/F81EE57C1EE533F2";
    fsType = "ntfs3";
    options = [
      "defaults"
      "nofail"
      "uid=1000"
      "gid=100"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=1min"
      "errors=continue" # Don't panic the kernel if metadata is weird
      "prele" # Pre-read lead-in (helps ntfs3 stability)
    ];
  };

  # --- NETWORKING ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    # IMPORTANT: Open 445/TCP (SMB) and 139/TCP (NetBIOS)
    allowedTCPPorts = [
      445
      139
      5357
    ];
    allowedUDPPorts = [
      137
      138
      3702
    ];
  };

  # Specific Locale Overrides (Common sets defaults, this overrides specific formats)
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  nix.settings = {
    # Change Nix download buffer size. I was getting errors about this.
    # Increase to 268435456 (256MB) if this is still too small.
    download-buffer-size = 134217728; # 128 MB
    # Allow Nix to run a build job for each of the computer's cores.
    max-jobs = "auto";
    # Remove limit on how many CPU cores each individual build job can use.
    cores = 0;
  };

  # --- DESKTOP ENVIRONMENT ---
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # This prevents the machine from going to sleep
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Prevent Gnome from trying to suspend on its own
  services.displayManager.gdm.autoSuspend = false;

  # Auto Login
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "home";

  # Disable TTY getters to prevent boot race conditions
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # --- USERS ---
  users.users.home = {
    isNormalUser = true;
    description = "home";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };

  # --- HOST SPECIFIC PACKAGES ---
  # GUI Apps and heavy tools specific to this desktop
  environment.systemPackages = with pkgs; [
    age
    efitools
    exiftool
    mesa
    nixd
    qbittorrent
    sops
    vulkan-tools
  ];

  # --- PROGRAMS ---
  programs.zsh.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
    alsa-lib # needed by Claude Code's VS Code extension audio-capture.node (voice input)
    # add more if `ldd` on the binary shows missing libs
  ];

  programs.gamemode.enable = true;

  services.printing.enable = true;
  zramSwap.enable = true;

  # --- SAMBA (File Sharing) ---
  # aka SMB in the configuration
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "nixos";
        "security" = "user";
        "log level" = "1 auth:3"; # Enable Auth Logging
        "logging" = "systemd";
        # Mac Compatibility
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";

        # ExFAT compatibility
        "fruit:resource" = "file";
      };

      "mule" = {
        "path" = "/drives/mule";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "home";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  # --- Avahi (Service Discover) ---
  # Open-source Apple Bonjour aka Zeroconf
  # Advertises Nixos on the network to Mac & PC
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?><!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      git-email = {
        owner = "home";
      };
      git-name = {
        owner = "home";
      };
    };

    # --- ADD THIS SECTION ---
    templates."git-user.conf" = {
      owner = "home";
      # This looks like a standard git config file
      content = ''
        [user]
          name = ${config.sops.placeholder.git-name}
          email = ${config.sops.placeholder.git-email}
      '';
    };
  };

  system.stateVersion = "23.05";
}
