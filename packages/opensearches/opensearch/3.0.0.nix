{ callPackage }:
callPackage ./generic.nix {
  version = "3.0.0";
  hashes = {
    "x86_64-linux" = "sha256-2Yxgv311uLQleyQh3SK4kVXoe+S1CdpqThE2z2LgsVU=";
    "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
