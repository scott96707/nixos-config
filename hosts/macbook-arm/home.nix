{ ... }:

let
  local = import ./local.nix;
in

{
  imports = [
    ./../../modules/darwin/home.nix
    ./../../modules/common/iterm2.nix
  ];

  myHome.username = local.username;
  myHome.flakeHost = "macbook-arm";
}
