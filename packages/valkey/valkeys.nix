nixpkgs: final: prev:

{
  valkey_8_0 = prev.callPackage ./valkey/8.0.nix { };
}
