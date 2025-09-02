{
  callPackage,
  erlang,
  elixir,
}:
callPackage ./generic.nix {
  version = "3.13.7";
  hash = "sha256-GDUyYudwhQSLrFXO21W3fwmH2tl2STF9gSuZsb3GZh0=";
  inherit
    erlang
    elixir
    ;
}
