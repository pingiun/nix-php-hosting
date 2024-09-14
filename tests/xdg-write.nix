projectModule:
{ pkgs, lib, ... }:
{
  name = "magento-project";

  nodes = {
    machine =
      { pkgs, ... }:
      {
        imports = [ projectModule ];
        projects.test = {
          xdg.configFile.test = {
            source = ''
              Test
            '';
          };
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("setup-project-test")
    machine.succeed("cat /project/test/.config/test | grep Test")
  '';
}
