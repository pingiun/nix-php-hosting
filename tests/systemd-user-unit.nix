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

        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("setup-project-test")
    machine.succeed("cat /project/test/.config/test | grep Test")
  '';
}
