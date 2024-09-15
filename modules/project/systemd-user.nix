{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
with lib;

let
  cfg = config.systemd;

  systemdUtils = utils.systemdUtils;

  inherit (utils.systemdUtils.lib)
    targetToUnit
    serviceToUnit
    sliceToUnit
    socketToUnit
    timerToUnit
    pathToUnit
    ;

in
{
  options = {

    systemd.units = mkOption {
      description = "Definition of systemd per-user units.";
      default = { };
      type = systemdUtils.types.units;
    };

    systemd.paths = mkOption {
      default = { };
      type = systemdUtils.types.paths;
      description = "Definition of systemd per-user path units.";
    };

    systemd.services = mkOption {
      default = { };
      type = systemdUtils.types.services;
      description = "Definition of systemd per-user service units.";
    };

    systemd.slices = mkOption {
      default = { };
      type = systemdUtils.types.slices;
      description = "Definition of systemd per-user slice units.";
    };

    systemd.sockets = mkOption {
      default = { };
      type = systemdUtils.types.sockets;
      description = "Definition of systemd per-user socket units.";
    };

    systemd.targets = mkOption {
      default = { };
      type = systemdUtils.types.targets;
      description = "Definition of systemd per-user target units.";
    };

    systemd.timers = mkOption {
      default = { };
      type = systemdUtils.types.timers;
      description = "Definition of systemd per-user timer units.";
    };

    systemd.tmpfiles = {
      rules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "D %C - - - 7d" ];
        description = ''
          Global user rules for creation, deletion and cleaning of volatile and
          temporary files automatically. See
          {manpage}`tmpfiles.d(5)`
          for the exact format.
        '';
      };

      users = mkOption {
        description = ''
          Per-user rules for creation, deletion and cleaning of volatile and
          temporary files automatically.
        '';
        default = { };
        type = types.attrsOf (
          types.submodule {
            options = {
              rules = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "D %C - - - 7d" ];
                description = ''
                  Per-user rules for creation, deletion and cleaning of volatile and
                  temporary files automatically. See
                  {manpage}`tmpfiles.d(5)`
                  for the exact format.
                '';
              };
            };
          }
        );
      };
    };

    systemd.generators = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = {
        systemd-gpt-auto-generator = "/dev/null";
      };
      description = ''
        Definition of systemd generators; see {manpage}`systemd.generator(5)`.

        For each `NAME = VALUE` pair of the attrSet, a link is generated from
        `/etc/systemd/user-generators/NAME` to `VALUE`.
      '';
    };

    systemd.additionalUpstreamUserUnits = mkOption {
      default = [ ];
      type = types.listOf types.str;
      example = [ ];
      description = ''
        Additional units shipped with systemd that should be enabled for per-user systemd instances.
      '';
      internal = true;
    };
  };

  config = {

    systemd.units =
      mapAttrs' (n: v: nameValuePair "${n}.path" (pathToUnit v)) cfg.paths
      // mapAttrs' (n: v: nameValuePair "${n}.service" (serviceToUnit v)) cfg.services
      // mapAttrs' (n: v: nameValuePair "${n}.slice" (sliceToUnit v)) cfg.slices
      // mapAttrs' (n: v: nameValuePair "${n}.socket" (socketToUnit v)) cfg.sockets
      // mapAttrs' (n: v: nameValuePair "${n}.target" (targetToUnit v)) cfg.targets
      // mapAttrs' (n: v: nameValuePair "${n}.timer" (timerToUnit v)) cfg.timers;

    # Generate timer units for all services that have a ‘startAt’ value.
    systemd.timers = mapAttrs (name: service: {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = service.startAt;
    }) (filterAttrs (name: service: service.startAt != [ ]) cfg.services);
  };
}
