# Declarative Infrastructure (NixOS & macOS)

This repository contains the **Infrastructure as Code (IaC)** for my personal workstations. It uses [Nix Flakes](https://nixos.wiki/wiki/Flakes) to share configurations, development tools, and dotfiles between a **NixOS Desktop** (Linux/AMD GPU) and **MacBooks** (Intel & Apple Silicon).

It is designed to provide a reproducible **Engineering environment**, featuring a unified terminal experience, consistent keybindings, and automated state management.

---

## 🏗 Architecture

The configuration is organized into a modular structure:

```markdown
├── flake.nix               # Entry point & dependency pinning (Nixpkgs 25.11)
├── flake.lock              # Exact package version lockfile
├── hosts/                  # Machine-specific configurations
│   ├── macbook/             # macOS Laptop, Intel (nix-darwin)
│   │   ├── configuration.nix
│   │   └── home.nix
│   ├── macbook-arm/         # macOS Laptop, Apple Silicon (nix-darwin)
│   │   ├── configuration.nix
│   │   ├── home.nix
│   │   └── local.nix        # Tracked; edit in place, then `git update-index --skip-worktree`
│   └── nixos/               # Linux Desktop (GNOME/Wayland + AMD ROCm)
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── home.nix
├── modules/                # Modular logic blocks
│   ├── common/              # Shared across all hosts (Neovim, Shell, WezTerm, VSCode)
│   ├── darwin/               # Shared across both macOS hosts (system defaults, home-manager)
│   ├── macbook/              # macOS-only (Git identity)
│   └── nixos/                # Linux-only (Firefox, GPU-specific Git)
└── secrets/                 # SOPS-managed encrypted secrets
```

---

## 🚀 Features

* **OS Management**: Fully declarative system state. If I wipe a machine, this repo restores it 100%.
* **Local Storage**: Automated, "self-healing" NTFS mounts for internal storage (The "Mule") with `systemd.automount`.
* **Terminal**: [WezTerm](https://wezfurlong.org/wezterm/) configured with **JetBrains Mono** and **Catppuccin** themes.
* **Editor**: [VS Code](https://code.visualstudio.com/) and [Neovim](https://neovim.io/) with custom Nix-managed configurations.
* **Networking**: Samba (SMB) configuration optimized for macOS interoperability and Avahi (Bonjour) discovery.

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
3. **Apple Silicon only**: Edit `hosts/macbook-arm/local.nix` with your macOS username, then run `git update-index --skip-worktree hosts/macbook-arm/local.nix` so it stops showing as locally modified.
4. **Apply**:
   * Intel: `sudo darwin-rebuild switch --flake ~/nixos-config#macbook-intel`
   * Apple Silicon: `sudo darwin-rebuild switch --flake ~/nixos-config#macbook-arm`

---

## 🔐 Secrets & Bootstrap (SOPS)

This configuration uses [sops-nix](https://github.com/Mic92/sops-nix) for secret management.

**Mandatory Requirement:**
Before applying a configuration for the first time, you must manually place your decryption key at the following location:
`/var/lib/sops-nix/key.txt`

If this file is missing, the `rebuild` command will fail to evaluate.

---

## 🛠 Usage & Cheatsheet

### The `rebuild` Command

This config installs a `rebuild` shell alias on each host that runs the correct switch command for that machine (defined per-host in each `home.nix`).

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
