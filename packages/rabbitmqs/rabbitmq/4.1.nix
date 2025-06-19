{
  callPackage,
  AppKit,
  Carbon,
  Cocoa,
  erlang,
  elixir,
}:
callPackage ./generic.nix {
  version = "4.1.1";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  inherit
    AppKit
    Carbon
    Cocoa
    erlang
    elixir
    ;
}
