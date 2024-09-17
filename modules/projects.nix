{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

with lib;

let

  cfg = config;

  inherit (utils.systemdUtils.lib) generateUnits;

  unitFiles =
    units:
    let
      units-package = generateUnits {
        type = "user";
        inherit units;
        upstreamUnits = [ ];
        upstreamWants = [ ];
      };
    in
    pkgs.runCommand "unit-files" { } ''
      mkdir -p $out/etc/xdg/systemd
      ln -s ${units-package} $out/etc/xdg/systemd/user
    '';

  projectModule = types.submoduleWith {
    description = "Project module";
    class = "project";
    specialArgs = {
      nixosConfig = config;
      modulesPath = builtins.toString ./project;
      inherit pkgs utils;
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
            packages = [ (unitFiles projectCfg.systemd.units) ] ++ projectCfg.project.userPackages;
          };
        }) cfg.projects;
        users.mutableUsers = false;
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
