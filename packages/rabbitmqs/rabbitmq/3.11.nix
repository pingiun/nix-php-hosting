{ callPackage
, AppKit
, Carbon
, Cocoa
}:
callPackage ./generic.nix {
  version = "3.11.28";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  inherit AppKit Carbon Cocoa;
}
