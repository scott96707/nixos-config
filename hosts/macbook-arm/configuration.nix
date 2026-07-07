{ ... }:
let
  local = import ./local.nix;
in
{
  imports = [
    ./../../modules/common/common.nix
    ./../../modules/darwin/system.nix
  ];

  myDarwin.username = local.username;
  myDarwin.extraCasks = [ "iterm2" ];
}
