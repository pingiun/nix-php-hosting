{
  callPackage,
  AppKit,
  Carbon,
  Cocoa,
  erlangR24,
  elixir_1_12,
}:
callPackage ./generic.nix {
  version = "3.9.14";
  hash = "sha256-c6GpB6CSCHiU9hTC9FkxyTc1UpNWxx5iP3y2dbTUfS0=";
  inherit AppKit Carbon Cocoa;
  erlang = erlangR24;
  elixir = elixir_1_12;
}
