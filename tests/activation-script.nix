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
          system.activationScripts.test = {
            supportsDryActivation = true;
            text = ''
              echo "Test" > $HOME/setup
            '';
          };
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("setup-project-test")
    machine.succeed("cat /project/test/setup | grep Test")
  '';
}
