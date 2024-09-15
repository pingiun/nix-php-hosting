projectModule:
{ pkgs, lib, ... }:
{
  name = "mariadb-user";

  nodes = {
    machine =
      { pkgs, ... }:
      {
        imports = [ projectModule ];
        projects.test = {
          services.mysql.enable = true;
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("mysql.service")
    # machine.succeed("cat /project/test/testing | grep Test")
  '';
}
