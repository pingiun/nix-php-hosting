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

in
{
  imports = [ ./projects.nix ];

  systemd.services = mapAttrs' (
    _: projectcfg:
    nameValuePair ("setup-project-${utils.escapeSystemdPath projectcfg.project.name}") {
      description = "Setup project ${projectcfg.project.name}";
      wantedBy = [ "multi-user.target" ];
      before = [ "systemd-user-sessions.service" ];

      unitConfig = {
        RequiresMountsFor = config.users.users.${projectcfg.project.name}.home;
      };

      serviceConfig = {
        User = projectcfg.project.username;
        Type = "oneshot";
        RemainAfterExit = "yes";
        TimeoutStartSec = "5m";
      };
      script = ''
        ${projectcfg.system.build.toplevel}/activate
      '';
    }
  ) cfg.projects;
}
