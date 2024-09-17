{
  pkgs,
  erlang,
  lib,
  callPackage,
  ...
}:

let
  callElixir =
    drv: args:
    let
      builder = callPackage ../generic-builder.nix args;
    in
    callPackage drv {
      mkDerivation = pkgs.makeOverridable builder;
    };
in
{
  elixir_1_17 = lib.callElixir ../1.17.nix {
    inherit erlang;
    debugInfo = true;
  };
}
