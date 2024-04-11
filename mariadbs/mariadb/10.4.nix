{ callPackage, darwin }:

callPackage ./generic.nix {
  # Supported until 2025-06-24
  version = "10.4.33";
  hash = "sha256-0";
  inherit (darwin) cctools;
  inherit (darwin.apple_sdk.frameworks) CoreServices;
};
