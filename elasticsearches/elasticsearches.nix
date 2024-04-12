nixpkgs:
final:
prev:

{
  elasticsearch_716 = (prev.callPackage ./elasticsearch/7.16.nix {}).override {
    elk7Version = "7.16.1";
  };
  elasticsearch_717 = prev.elasticsearch;
  elasticsearch_84 = (prev.callPackage ./elasticsearch/8.4.nix {}).override {
    elk7Version = "8.4.3";
  };
  elasticsearch_85 = (prev.callPackage ./elasticsearch/8.5.nix {}).override {
    elk7Version = "8.5.3";
  };
}
