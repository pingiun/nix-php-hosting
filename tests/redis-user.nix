projectModule:
{ lib, ... }:
{
  name = "redis";
  meta.maintainers = with lib.maintainers; [ flokli ];

  nodes = {
    machine =
      { pkgs, lib, ... }:

      {
        imports = [ projectModule ];
        projects.test = {
          services.redis.servers."".enable = true;
        };
      };
  };

  testScript =
    { nodes, ... }:
    let
      inherit (nodes.machine.projects.test.services) redis;
    in
    ''
      start_all()
      machine.wait_for_unit("redis", "test")

      machine.wait_for_file("${redis.servers."".unixSocket}")

      # The unix socket is accessible to the redis group
      machine.succeed('su test -c "redis-cli -s ${redis.servers."".unixSocket} ping | grep PONG"')
    '';
}
