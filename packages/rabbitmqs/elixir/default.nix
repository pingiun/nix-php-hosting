{
  pkgs,
  erlang,
  erlang_26,
  erlang_27,
  lib,
  callPackage,
  ...
}:

let
  callElixir =
    drv: args:
    let
      builder = callPackage ./generic-builder.nix args;
    in
    callPackage drv {
      mkDerivation = pkgs.makeOverridable builder;
    };
in
{
  elixir_1_15 = callElixir ./1.15.nix {
    erlang = erlang_26;
    debugInfo = true;
  };
  elixir_1_17 = callElixir ./1.17.nix {
    erlang = erlang_27;
    debugInfo = true;
  };
}
