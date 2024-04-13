nixpkgs:
final:
prev:

{
  elasticsearch_79 = (prev.callPackage ./elasticsearch/7.9.nix {}).override {
    elk7Version = "7.9.3";
    jre_headless = prev.jdk11_headless;
  };
  elasticsearch_716 = (prev.callPackage ./elasticsearch/7.16.nix {}).override {
    elk7Version = "7.16.1";
    jre_headless = prev.jdk11_headless;
  };
  elasticsearch_717 = prev.elasticsearch;
  elasticsearch_84 = (prev.callPackage ./elasticsearch/8.4.nix {}).override {
    elk7Version = "8.4.3";
    jre_headless = prev.jdk17_headless;
  };
  elasticsearch_85 = (prev.callPackage ./elasticsearch/8.5.nix {}).override {
    elk7Version = "8.5.3";
    jre_headless = prev.jdk17_headless;
  };
  elasticsearch_811 = (prev.callPackage ./elasticsearch/8.11.nix {}).override {
    elk7Version = "8.11.4";
    jre_headless = prev.jdk17_headless;
  };
}
