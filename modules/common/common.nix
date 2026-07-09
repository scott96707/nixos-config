{ config, pkgs, lib, ... }:

{
  # --- NIX SETTINGS ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Use 'nix.optimise.automatic' for macOS, 'auto-optimise-store' setting for Linux
  nix.optimise.automatic = lib.mkIf pkgs.stdenv.isDarwin true;
  nix.settings.auto-optimise-store = lib.mkIf pkgs.stdenv.isLinux true;

  # --- GARBAGE COLLECTION ---
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };

  # --- LOCALE & TIME ---
  time.timeZone = "America/Denver";

  # --- CORE SYSTEM PACKAGES ---
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    jq
    ripgrep
    tree
    unzip
    wget
    nixfmt
    silver-searcher
  ];

  nixpkgs.config.allowUnfree = true;

  # --- FONTS ---
  fonts.packages = with pkgs; [
    noto-fonts 
    noto-fonts-cjk-sans 
    noto-fonts-color-emoji
    liberation_ttf 
    fira-code 
    fira-code-symbols
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];
}
