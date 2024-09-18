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
          services.rabbitmq = {
            enable = true;
            package = pkgs.phpHosting.rabbitmq."3.13";

            managementPlugin.enable = true;
          };
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("setup-project-test.service")
    machine.wait_for_unit("rabbitmq.service", "test")


  '';
}
