nixpkgs:
final:
prev:
{
  opensearch_212 = prev.callPackage ./opensearch/2.12.nix {};
}
