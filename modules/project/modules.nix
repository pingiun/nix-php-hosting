{ pkgs }:
let
  modules = [
    ./activation.nix
    ./project-environment.nix
    ./top-level.nix
    (pkgs.path + "/nixos/modules/misc/assertions.nix")
    (pkgs.path + "/nixos/modules/misc/meta.nix")
  ];
in
modules
