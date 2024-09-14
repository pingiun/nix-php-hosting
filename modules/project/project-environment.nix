{
  nixosConfig,
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.project;

in

{
  options = {
    project.name = mkOption {
      type = types.str;
      description = ''
        The project name
      '';
    };

    project.username = mkOption {
      type = types.str;
      defaultText = "the project name";
      readOnly = true;
      description = ''
        Name of the user created for this project
      '';
    };

    project.homeDirectory = mkOption {
      type = types.str;
      readOnly = true;
      description = ''
        The home directory of the project user
      '';
    };
  };

  config = {
    project.username = cfg.name;
    project.homeDirectory = nixosConfig.users.users.${cfg.name}.home;
  };
}
