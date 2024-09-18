{ pkgs }:
let
  modules = [
    ./activation.nix
    ./files.nix
    ./project-environment.nix
    ./services/mariadb.nix
    ./services/rabbitmq.nix
    ./services/redis.nix
    ./systemd-user.nix
    ./top-level.nix
    ./xdg.nix
    (pkgs.path + "/nixos/modules/misc/assertions.nix")
    (pkgs.path + "/nixos/modules/misc/meta.nix")
  ];
in
modules
