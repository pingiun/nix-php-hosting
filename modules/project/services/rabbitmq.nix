{ config, lib, pkgs, ... }:
let
  cfg = config.services.rabbitmq;

  config_file_content = lib.generators.toKeyValue { } cfg.configItems;
  config_file = pkgs.writeText "rabbitmq.conf" config_file_content;

  advanced_config_file = pkgs.writeText "advanced.config" cfg.config;

in
{
  ###### interface
  options = {
    services.rabbitmq = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the RabbitMQ server, an Advanced Message
          Queuing Protocol (AMQP) broker.
        '';
      };

      package = lib.mkPackageOption pkgs "rabbitmq-server" { };

      listenAddress = lib.mkOption {
        default = "127.0.0.1";
        example = "";
        description = ''
          IP address on which RabbitMQ will listen for AMQP
          connections.  Set to the empty string to listen on all
          interfaces.  Note that RabbitMQ creates a user named
          `guest` with password
          `guest` by default, so you should delete
          this user if you intend to allow external access.

          Together with 'port' setting it's mostly an alias for
          configItems."listeners.tcp.1" and it's left for backwards
          compatibility with previous version of this module.
        '';
        type = lib.types.str;
      };

      port = lib.mkOption {
        default = 5672;
        description = ''
          Port on which RabbitMQ will listen for AMQP connections.
        '';
        type = lib.types.port;
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "${config.xdg.stateHome}/rabbitmq";
        description = ''
          Data directory for rabbitmq.
        '';
      };

      configItems = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.str;
        example = lib.literalExpression ''
          {
            "auth_backends.1.authn" = "rabbit_auth_backend_ldap";
            "auth_backends.1.authz" = "rabbit_auth_backend_internal";
          }
        '';
        description = ''
          Configuration options in RabbitMQ's new config file format,
          which is a simple key-value format that can not express nested
          data structures. This is known as the `rabbitmq.conf` file,
          although outside NixOS that filename may have Erlang syntax, particularly
          prior to RabbitMQ 3.7.0.

          If you do need to express nested data structures, you can use
          `config` option. Configuration from `config`
          will be merged into these options by RabbitMQ at runtime to
          form the final configuration.

          See https://www.rabbitmq.com/configure.html#config-items
          For the distinct formats, see https://www.rabbitmq.com/configure.html#config-file-formats
        '';
      };

      config = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = ''
          Verbatim advanced configuration file contents using the Erlang syntax.
          This is also known as the `advanced.config` file or the old config format.

          `configItems` is preferred whenever possible. However, nested
          data structures can only be expressed properly using the `config` option.

          The contents of this option will be merged into the `configItems`
          by RabbitMQ at runtime to form the final configuration.

          See the second table on https://www.rabbitmq.com/configure.html#config-items
          For the distinct formats, see https://www.rabbitmq.com/configure.html#config-file-formats
        '';
      };

      plugins = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        description = "The names of plugins to enable";
      };

      pluginDirs = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.path;
        description = "The list of directories containing external plugins";
      };

      managementPlugin = {
        enable = lib.mkEnableOption "the management plugin";
        port = lib.mkOption {
          default = 15672;
          type = lib.types.port;
          description = ''
            On which port to run the management plugin
          '';
        };
      };
    };
  };


  ###### implementation
  config = lib.mkIf cfg.enable {

    # This is needed so we will have 'rabbitmqctl' in our PATH
    project.userPackages = [ cfg.package ];

    # services.epmd.enable = true;

    services.rabbitmq.configItems = {
      "listeners.tcp.1" = lib.mkDefault "${cfg.listenAddress}:${toString cfg.port}";
    } // lib.optionalAttrs cfg.managementPlugin.enable {
      "management.tcp.port" = toString cfg.managementPlugin.port;
      "management.tcp.ip" = cfg.listenAddress;
    };

    services.rabbitmq.plugins = lib.optional cfg.managementPlugin.enable "rabbitmq_management";

    systemd.services.rabbitmq = {
      description = "RabbitMQ Server";

      wantedBy = [ "default.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      path = [
        "" # Add /bin for /bin/sh
        cfg.package
        pkgs.coreutils # mkdir/chown/chmod for preStart
      ];

      environment = {
        RABBITMQ_MNESIA_BASE = "${cfg.dataDir}/mnesia";
        RABBITMQ_LOGS = "-";
        SYS_PREFIX = "";
        RABBITMQ_CONFIG_FILE = config_file;
        RABBITMQ_PLUGINS_DIR = lib.concatStringsSep ":" cfg.pluginDirs;
        RABBITMQ_ENABLED_PLUGINS_FILE = pkgs.writeText "enabled_plugins" ''
          [ ${lib.concatStringsSep "," cfg.plugins} ].
        '';
      } // lib.optionalAttrs (cfg.config != "") { RABBITMQ_ADVANCED_CONFIG_FILE = advanced_config_file; };

      serviceConfig = {
        ExecStart = "${cfg.package}/sbin/rabbitmq-server";
        ExecStop = "${cfg.package}/sbin/rabbitmqctl shutdown";

        LogsDirectory = "rabbitmq";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "rabbitmq";
        Type = "notify";
        NotifyAccess = "all";
        UMask = "0027";
        LimitNOFILE = "100000";
        Restart = "on-failure";
        RestartSec = "10";
        TimeoutStartSec = "3600";
      };
    };

  };

}
