{ config, lib, pkgs, utils, ... }:

with lib;

let
  cfg = config.services.magento;

  magentoVersionToPhp = {
    "2.4.2" = "7.4";
    "2.4.3" = "7.4";
    "2.4.4" = "8.1";
    "2.4.5" = "8.1";
    "2.4.6" = "8.2";
    "2.4.7" = "8.3";
  };

  projectOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = with types; nullOr (types.passwdEntry types.str);
        apply = x: assert (builtins.stringLength x < 32 || abort "Project name '${x}' is longer than 31 characters which is not allowed!"); x;
        description = "Project name. Will also be used as the unix username. If left undefined, the name of the attribute set will be used.";
      };
      magentoVersion = mkOption {
        type = with types; nullOr (enum [ "2.4.2" "2.4.3" "2.4.4" "2.4.5" "2.4.6" "2.4.7" ]);
        default = null;
        description = "Magento version, informs the default versions of the other software.";
      };
      phpVersion = mkOption {
        type = with types; nullOr (enum [ "5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3" ]);
        default = null;
        defaultText = "Latest supported version by magentoVersion";
        description = "PHP version.";
      };
      mysqlVersion = mkOption {
        type = with types; nullOr (enum [ "5.7" "8.0" ]);
        default = null;
        description = "MySQL version.";
      };
      mariadbVersion = mkOption {
        type = with types; nullOr (enum [ "10.4" "10.6" ]);
        default = null;
        description = "MariaDB version.";
      };
      elasticsearchVersion = mkOption {
        type = with types; nullOr (enum [ "7.9" "7.16" "7.17" "8.4" "8.5" "8.11" ]);
        default = null;
        description = "Elasticsearch version. Set to null to not enable.";
      };
      opensearchVersion = mkOption {
        type = with types; nullOr (enum [ "1.2" "1.3" "2.5" "2.12" ]);
        default = null;
        description = "OpenSearch version. Set to null to not enable.";
      };
      rabbitmqVersion = mkOption {
        type = with types; nullOr (enum [ "3.11" "3.12" "3.13" ]);
        default = null;
        description = "RabbitMQ version. Set to null to not enable.";
      };
      redisVersion = mkOption {
        type = with types; nullOr (enum [ "6.0" "6.2" "7.0" "7.2" ]);
        default = "7.2";
        description = "Redis version. Set to null to not enable.";
      };
      varnishVersion = mkOption {
        type = with types; nullOr (enum [ "6.4" "6.5" "7.0" "7.1" "7.3" "7.5" ]);
        default = "7.5";
        description = "Varnish version. Set to null to not enable.";
      };
    };

    config = mkMerge
      [{
        name = mkDefault name;
        phpVersion = mkDefault magentoVersionToPhp.${config.magentoVersion};
      }];
  };
in
{
  options = {
    services.magento = {
      projects = mkOption {
        type = with types; types.attrsOf (submodule projectOpts);
        default = { };
      };
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = all (project: !(project.mariadbVersion != null && project.mysqlVersion != null)) (attrValues cfg.projects);
          message = "Both `mysqlVersion` and `mariadbVersion` can't be set at the same time.";
        }
        {
          assertion = all (project: project.mysqlVersion != null || project.mariadbVersion != null) (attrValues cfg.projects);
          message = "Either `mysqlVersion` or `mariadbVersion` must be set.";
        }
        {
          assertion = all (project: !(project.opensearchVersion != null && project.elasticsearchVersion != null)) (attrValues cfg.projects);
          message = "Both `opensearchVersion` and `elasticsearchVersion` can't be set at the same time.";
        }
        {
          assertion = all (project: project.opensearchVersion != null || project.elasticsearchVersion != null) (attrValues cfg.projects);
          message = "Either `opensearchVersion` or `elasticsearchVersion` must be set.";
        }
      ];
    }
    (mkIf (cfg.projects != { }) {
      users.users = mapAttrs'
        (_: { name, ... }: {
          inherit name;
          value = {
            description = "Magento project user";
            isNormalUser = true;
            createHome = true;
            linger = true;
          };
        })
        cfg.projects;

      systemd.services = mapAttrs'
        (_: projectcfg:
          nameValuePair ("setup-project-${utils.escapeSystemdPath projectcfg.name}") {
            description = "Setup Magento project ${projectcfg.name}";
            wantedBy = [ "multi-user.target" ];
            before = [ "systemd-user-sessions.service" ];

            unitConfig = { RequiresMountsFor = config.users.users.${projectcfg.name}.home; };

            serviceConfig = {
              User = projectcfg.name;
              Type = "oneshot";
              RemainAfterExit = "yes";
              TimeoutStartSec = "5m";
            };
            script = ''
              echo "Test" > "${config.users.users.${projectcfg.name}.home}/setup";
            '';
          }
        )
        cfg.projects;
    })
  ];
}
