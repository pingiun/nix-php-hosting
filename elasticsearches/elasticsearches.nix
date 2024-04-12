nixpkgs:
final:
prev:

{
  elasticsearch_716 = prev.elasticsearch.override {
    elk7Version = "7.16.1";
  };
  elasticsearch_717 = prev.elasticsearch;
}
