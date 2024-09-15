projectModule:
{ pkgs, lib, ... }:
{
  name = "systemd-user-unit";

  nodes = {
    machine =
      { pkgs, ... }:
      {
        imports = [ projectModule ];
        projects.test = {
          systemd.services.testing = {
            description = "Test service";
            wantedBy = [ "default.target" ];

            script = ''
              echo Test > $HOME/testing
            '';
          };
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")
    machine.succeed("cat /project/test/testing | grep Test")
  '';
}
