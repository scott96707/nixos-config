{ ... }:

{
  imports = [
    ./../../modules/darwin/home.nix
    ./../../modules/common/wezterm.nix
  ];

  myHome.username = "work_machine";
  myHome.flakeHost = "macbook-intel";
}
