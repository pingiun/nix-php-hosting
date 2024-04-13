{ callPackage
, AppKit
, Carbon
, Cocoa
}:
callPackage ./generic.nix {
  version = "3.9.29";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  inherit AppKit Carbon Cocoa;
}
