{ pkgs, lib, ... }:
{
  name = "elasticsearch";

  nodes.machine =
    { config, ... }:
    with lib;
    {
      imports = [ ./elasticsearch-patched-module.nix ];
      disabledModules = [ "services/search/elasticsearch.nix" ];

      virtualisation.memorySize = 4096;
      services.elasticsearch = {
        enable = true;
        extraConf = ''
          xpack.security.enabled: false
          xpack.security.transport.ssl.enabled: false
          xpack.security.http.ssl.enabled: false
        '';
      };
      systemd.services.elasticsearch.environment.ES_JAVA_HOME = pkgs.jdk17_headless;
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("elasticsearch.service")
    machine.wait_for_open_port(9200)

    machine.succeed(
        "curl --fail http://localhost:9200"
    )
  '';
}
