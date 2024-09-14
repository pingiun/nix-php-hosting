{ pkgs }:
let
  modules = [
    ./project-environment.nix
    (pkgs.path + "/nixos/modules/misc/assertions.nix")
    (pkgs.path + "/nixos/modules/misc/meta.nix")
  ];
in
modules
