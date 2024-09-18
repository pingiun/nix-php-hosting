{ pkgs, lib, ... }:
{
  name = "opensearch";
  meta.maintainers = with pkgs.lib.maintainers; [ shyim ];

  nodes.machine =
    { config, ... }:
    with lib;
    {
      virtualisation.memorySize = 2048;
      services.elasticsearch.enable = true;
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("elasticsearch.service")
    machine.wait_for_open_port(9200)

    machine.succeed(
        "curl --fail localhost:9200"
    )
  '';
}
