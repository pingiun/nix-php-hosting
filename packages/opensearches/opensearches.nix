nixpkgs:
final:
prev:
{
  opensearch_12 = prev.callPackage ./opensearch/1.2.nix {};
  opensearch_13 = prev.callPackage ./opensearch/1.3.nix {};
  opensearch_25 = prev.callPackage ./opensearch/2.5.nix {};
  opensearch_212 = prev.callPackage ./opensearch/2.12.nix {};
}
