# Declarative Infrastructure (NixOS & macOS)

This repository contains the **Infrastructure as Code (IaC)** for my personal machines. It uses [Nix Flakes](https://nixos.wiki/wiki/Flakes) to share configurations, development tools, and dotfiles across four hosts:

| Host | Hardware | Role |
| --- | --- | --- |
| `nixos` | Linux desktop, AMD GPU | Workstation (GNOME/Wayland) |
| `macbook-intel` | MacBook, Intel | Workstation (nix-darwin) |
| `dp21` | MSI PRO DP21, i5-14400 | Media appliance — Jellyfin/Arr + Prometheus |
| `pi` | Raspberry Pi 4 | Network appliance — AdGuard DNS + Caddy |

The two workstations run **home-manager**; the two appliances deliberately do not — nothing interactive runs on them, and less machinery on the box that owns household DNS means less to break. Settings that must reach every host (git identity, editor) are therefore set at the **system** level rather than through home-manager.

It is designed to provide a reproducible **Engineering environment**, featuring a unified terminal experience, consistent keybindings, and automated state management.

---

## 🏗 Architecture

The configuration is organized into a modular structure:

```markdown
├── flake.nix               # Entry point & dependency pinning (Nixpkgs 26.05)
├── flake.lock              # Exact package version lockfile
├── hosts/                  # Machine-specific configurations
│   ├── macbook/             # macOS Laptop, Intel (nix-darwin)
│   │   ├── configuration.nix
│   │   └── home.nix
│   ├── nixos/               # Linux Desktop (GNOME/Wayland + AMD ROCm)
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── home.nix
│   ├── dp21/                # MSI PRO DP21, media appliance (no home-manager)
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── pi/                  # Raspberry Pi 4, DNS/network appliance (no home-manager)
│       └── configuration.nix
├── modules/                # Modular logic blocks
│   ├── common/              # Shared across all hosts (Neovim, Shell, WezTerm, VSCode,
│   │                        #   git-identity.nix — commit name/email for every host)
│   ├── darwin/               # macOS-specific (system defaults, home-manager)
│   ├── macbook/              # macOS-only (Git identity)
│   └── nixos/                # Linux-only (Firefox, GPU-specific Git)
└── secrets/                 # SOPS-managed encrypted secrets
```

---

## 🚀 Features

* **OS Management**: Fully declarative system state. If I wipe a machine, this repo restores it 100%.
* **Local Storage**: Automated, "self-healing" NTFS mounts for internal storage (The "Mule") with `systemd.automount`.
* **Terminal**: [WezTerm](https://wezfurlong.org/wezterm/) configured with **JetBrains Mono** and **Catppuccin** themes.
* **Editor**: [VS Code](https://code.visualstudio.com/) and [Neovim](https://neovim.io/) with custom Nix-managed configurations. `vim` is the editor on every host — on the workstations it is aliased to Neovim, on the appliances it is plain vim.
* **Git identity**: One commit name/email for all hosts, from `modules/common/git-identity.nix`, with SSH commit signing. Each host has its own key at `~/.ssh/id_ed25519`, registered on GitHub as both an Authentication and a Signing key.
* **Networking**: Samba (SMB) configuration optimized for macOS interoperability and Avahi (Bonjour) discovery.
* **Homelab**: The appliances pull their service definitions from separate flake inputs — [`media-server`](https://github.com/scott96707/media-server), [`homelab-network`](https://github.com/scott96707/homelab-network), and [`manga-aggregator`](https://github.com/scott96707/manga-aggregator). After changing one of those repos, run `nix flake update <input>` here.
* **Remote development**: `dp21` enables `programs.nix-ld` so VS Code Remote-SSH can run its downloaded server. Note that the manga-aggregator and media-server units run *out of the `~/projects` checkouts on that host*, so edits there take effect on unit restart — but changes to those repos' Nix modules still need a push plus `nix flake update`.

---

## 🐧 Installation on NixOS (Linux)

1. **Partition & Install**: Minimal install with user `home`.
2. **Clone & Setup**:

   ```bash
   git clone https://github.com/scott96707/nixos-config ~/nixos-config
   ```

3. **Hardware Config**: Copy `/etc/nixos/hardware-configuration.nix` into `~/nixos-config/hosts/nixos/`.
4. **Secrets**: Ensure your `key.txt` is in `/var/lib/sops-nix/`.
5. **Apply**: `sudo nixos-rebuild switch --flake ~/nixos-config#nixos`

## 🍎 Installation on macOS

1. **Install Nix**: Via [Determinate Systems](https://install.determinate.systems/nix).
2. **Enable Flakes**: Add `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf`.
3. **Apply**: `sudo darwin-rebuild switch --flake ~/nixos-config#macbook-intel`

## 📦 The Appliances (`dp21`, `pi`)

Both are headless and have no home-manager. SSH is the only way in after first boot, and password auth is disabled — the authorized keys are declared in each host's `configuration.nix`, so a new client key must be added there and applied from an already-trusted machine.

1. **Install**: Minimal NixOS with user `home`. The Pi uses the aarch64 sd-image (extlinux, no GRUB); `dp21` uses systemd-boot.
2. **Hardware config** (`dp21` only): copy `/etc/nixos/hardware-configuration.nix` into `hosts/dp21/`. The Pi has a fixed sd-image layout declared inline.
3. **Git identity**: each appliance needs its own `~/.ssh/id_ed25519`, with the public half registered on GitHub as an Authentication *and* a Signing key. `commit.gpgsign` is on, so a missing key makes commits fail rather than silently produce unsigned ones.
4. **Apply**, on the box itself: `rebuild` (aliased to `sudo nixos-rebuild switch --flake ~/nixos-config`; with no `#attr` it defaults to the hostname).

---

## 🔐 Secrets & Bootstrap (SOPS)

This configuration wires up [sops-nix](https://github.com/Mic92/sops-nix), but **no secrets are currently defined**. Git name/email used to live here and have moved to `modules/common/git-identity.nix` — the GitHub noreply address is public by construction, so encrypting it bought nothing while preventing the home-manager-less appliances from having any git identity at all.

The scaffolding (`defaultSopsFile`, `age.keyFile`) is kept so the next real secret is a one-line addition. With zero secrets declared, sops-nix is inert and a **missing key file will not block a rebuild**.

When you do add a secret, the decryption key must be present first:

* NixOS / appliances: `/var/lib/sops-nix/key.txt`
* macOS: `~/.config/sops/age/keys.txt`

Each host needs its own age key, with the public half added to `.sops.yaml` followed by `sops updatekeys secrets/secrets.yaml` — otherwise nothing decrypts on that host.

---

## 🛠 Usage & Cheatsheet

### The `rebuild` Command

This config installs a `rebuild` shell alias on each host that runs the correct switch command for that machine. On the workstations it is defined in that host's `home.nix`; on the appliances, which have no home-manager, it is set system-wide via `programs.zsh.shellAliases` in `configuration.nix`.

* **Apply Changes:**

  ```bash
  rebuild
  ```

* **Update System (Fetch latest packages):**

  ```bash
  nix flake update
  rebuild
  ```

### Storage Maintenance

If the internal **Mule** drive becomes unreachable or "dirty" due to a hard reset:

```bash
# Force repair the NTFS metadata
sudo ntfsfix -d /dev/disk/by-label/Mule
```
