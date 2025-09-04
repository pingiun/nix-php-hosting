{
  callPackage,
  erlang,
  elixir,
}:
callPackage ./generic.nix {
  version = "4.1.4";
  hash = "sha256-dqNdrbXSysYUMN+6gMMb9GXKER/mOGXgW6j3iOLHNks=";
  inherit
    erlang
    elixir
    ;
}
