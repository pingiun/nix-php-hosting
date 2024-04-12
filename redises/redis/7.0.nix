{ callPackage, lib, ... }:
callPackage ./generic {
  version = "7.0.0";
  hash = lib.fakeHash;
}
