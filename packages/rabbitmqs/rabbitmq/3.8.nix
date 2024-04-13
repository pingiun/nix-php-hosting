{ callPackage
, AppKit
, Carbon
, Cocoa
}:
callPackage ./generic.nix {
  version = "3.11.35";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  inherit AppKit Carbon Cocoa;
}
