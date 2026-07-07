{ ... }:
{
  imports = [
    ./../../modules/common/common.nix
    ./../../modules/darwin/system.nix
  ];

  myDarwin.username = "work_machine";
}
