{ callPackage
, AppKit
, Carbon
, Cocoa
, elixir
}:
callPackage ./generic.nix {
  version = "3.11.28";
  hash = "sha256-heOzYhtqEnIU8Tt1P5r9l3bYZS9rFGnknZgCf3X0HKo=";
  inherit AppKit Carbon Cocoa elixir;
}
