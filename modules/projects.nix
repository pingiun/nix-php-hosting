{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config;

  unitFiles =
    package:
    pkgs.runCommand "unit-files" { } ''
      mkdir -p $out/etc/xdg/systemd
      ln -s ${package}/user $out/etc/xdg/systemd/user
    '';

  projectModule = types.submoduleWith {
    description = "Project module";
    class = "project";
    specialArgs = {
      nixosConfig = config;
      modulesPath = builtins.toString ./project;
      inherit pkgs;
    };
    modules = [
      (
        { name, ... }:
        {
          imports = import ./project/modules.nix { inherit pkgs; };

          config = {
            project.name = "${name}";
          };
        }
      )
    ];
  };

in
{
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

  config = (
    mkMerge [
      (mkIf (cfg.projects != { }) {
        users.users = mapAttrs' (name: projectCfg: {
          inherit name;
          value = {
            description = mkDefault "Project user";
            isNormalUser = true;
            createHome = true;
            home = "/project/${name}";
            linger = true;
            packages = [ (unitFiles projectCfg.system.build.systemd-units) ];
          };
        }) cfg.projects;
        systemd.tmpfiles.rules = [ "d /project 0755 root root" ];
      })

      (mkIf (cfg.projects != { }) {
        warnings = flatten (
          flip mapAttrsToList cfg.projects (
            user: config: flip map config.warnings (warning: "${user} profile: ${warning}")
          )
        );

        assertions = flatten (
          flip mapAttrsToList cfg.projects (
            user: config:
            flip map config.assertions (assertion: {
              inherit (assertion) assertion;
              message = "${user} profile: ${assertion.message}";
            })
          )
        );
      })
    ]
  );
}
