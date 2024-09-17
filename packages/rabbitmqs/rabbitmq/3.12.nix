{
  callPackage,
  AppKit,
  Carbon,
  Cocoa,
  elixir,
  erlang,
}:
callPackage ./generic.nix {
  version = "3.12.13";
  hash = "sha256-UjUkiS8ay66DDzeW9EXOJPQVHHxC1sXT8mCn+KVXSQ4=";
  inherit
    AppKit
    Carbon
    Cocoa
    elixir
    erlang
    ;
}
