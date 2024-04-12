nixpkgs:
final:
prev:

{
  elasticsearch_716 = (prev.callPackage ./7.16.nix {}).override {
    elk7Version = "7.16.1";
  };
  elasticsearch_717 = prev.elasticsearch;
  elasticsearch_84 = (prev.callPackage ./8.4.nix {}).override {
    elk7Version = "8.4.3";
  };
}
