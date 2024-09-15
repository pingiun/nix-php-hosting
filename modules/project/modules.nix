{ pkgs }:
let
  modules = [
    ./activation.nix
    ./files.nix
    ./project-environment.nix
    ./top-level.nix
    # ./xdg.nix
    ./systemd-user.nix
    (pkgs.path + "/nixos/modules/misc/assertions.nix")
    (pkgs.path + "/nixos/modules/misc/meta.nix")
  ];
in
modules
