{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.projects;

  projectModule = types.submoduleWith {
    description = "Project module";
    class = "project";
    specialArgs = {
      osConfig = config;
      modulesPath = builtins.toString ./project;
    };
    modules = [
      ({ name, ... }: {
        imports = import ../project/modules.nix {
          inherit pkgs;
        };

        config = {
          project.name = ${name};
        };
      })
    ];
  };

in {
  options = {
    projects = mkOption {
      type = types.attrsOf projectModule;
      default = { };
      # Prevent the entire submodule being included in the documentation.
      visible = "shallow";
      description = ''
        Per project services configuration
      '';
    };
  };

  config = (mkMerge [
    users.users = mapAttrs'
        (_: { name, ... }: {
          inherit name;
          value = {
            description = mkDefault "Project user";
            isNormalUser = true;
            createHome = true;
            home = "/project/${name}";
            linger = true;
          };
        })
        cfg.projects;

    (mkIf (cfg.users != { }) {
      warnings = flatten (flip mapAttrsToList cfg.users (user: config:
        flip map config.warnings (warning: "${user} profile: ${warning}")));

      assertions = flatten (flip mapAttrsToList cfg.users (user: config:
        flip map config.assertions (assertion: {
          inherit (assertion) assertion;
          message = "${user} profile: ${assertion.message}";
        })));
    })
  ]);
}
