projectModule:
{ pkgs, lib, ... }:
{
  name = "elasticsearch";

  nodes.machine =
    { config, ... }:

    {
      imports = [ projectModule ];

      virtualisation.memorySize = 4096;
      projects.test = {
        services.elasticsearch = {
          enable = true;
          package = pkgs.phpHosting.elasticsearch."8.11";
        };
      };
    };

  testScript = ''
    machine.start()

    machine.wait_for_unit("setup-project-test.service")
    machine.wait_for_unit("elasticsearch.service", "test")
    machine.wait_for_open_port(9200)

    machine.succeed(
        "curl --fail http://localhost:9200"
    )
  '';
}
