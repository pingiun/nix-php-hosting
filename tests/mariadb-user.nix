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
          services.mysql = {
            enable = true;
            package = pkgs.mariadb_106;
          };
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("linger-users.service")
    machine.wait_for_unit("mysql.service", "test")
    # machine.succeed("cat /project/test/testing | grep Test")
  '';
}
