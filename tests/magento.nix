{ pkgs, lib, ... }:
{
  name = "magento-project";

  nodes = {
    machine =
      { pkgs, ... }: {
        services.magento.projects.test = {
          magentoVersion = "2.4.7";
        };

      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("setup-project-test")
  '';
}
