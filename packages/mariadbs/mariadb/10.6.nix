{ callPackage, darwin }:

(callPackage ./generic.nix {
  # Supported until 2026-07-06
  version = "10.6.18";
  hash = "sha256-aJihER9HEwcJ4ouix70aV+S7VxAfbhCeWX1R5tOFzxg=";
  inherit (darwin) cctools;
  inherit (darwin.apple_sdk.frameworks) CoreServices;
})
