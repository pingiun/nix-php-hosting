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
      after = [ "systemd-user-sessions.service" ];

      unitConfig = {
        RequiresMountsFor = config.users.users.${projectcfg.project.name}.home;
      };

      serviceConfig =
        let
          prestartScript = pkgs.writeShellScript "activate-pre-start" ''
            ln -s /run/user/$(id -u ${projectcfg.project.username}) /run/user/${projectcfg.project.username}
          '';
        in
        {
          User = projectcfg.project.username;
          Type = "oneshot";
          RemainAfterExit = "yes";
          TimeoutStartSec = "5m";
          ExecStartPre = "!${prestartScript}";
        };
      script = ''
        ${projectcfg.system.build.toplevel}/activate
      '';
    }
  ) cfg.projects;
}
