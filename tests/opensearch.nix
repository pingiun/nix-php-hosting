{ pkgs, lib, ... }: {
  name = "opensearch";
  meta.maintainers = with pkgs.lib.maintainers; [ shyim ];

  nodes.machine =
    {
      virtualisation.memorySize = 2048;
      services.opensearch.enable = true;
      systemd.services.opensearch.serviceConfig.ExecStartPre =
          let
            startPreFullPrivileges = ''
              set -o errexit -o pipefail -o nounset -o errtrace
              shopt -s inherit_errexit
            '' + (optionalString (!config.boot.isContainer) ''
              # Only set vm.max_map_count if lower than ES required minimum
              # This avoids conflict if configured via boot.kernel.sysctl
              if [ $(${pkgs.procps}/bin/sysctl -n vm.max_map_count) -lt 262144 ]; then
                ${pkgs.procps}/bin/sysctl -w vm.max_map_count=262144
              fi
            '');
            startPreUnprivileged = ''
              set -o errexit -o pipefail -o nounset -o errtrace
              shopt -s inherit_errexit

              # Install plugins

              # remove plugins directory if it is empty.
              if [[ -d ${cfg.dataDir}/plugins && -z "$(ls -A ${cfg.dataDir}/plugins)" ]]; then
                rm -r "${cfg.dataDir}/plugins"
              fi

              ln -sfT "${cfg.package}/plugins" "${cfg.dataDir}/plugins"
              ln -sfT ${cfg.package}/lib ${cfg.dataDir}/lib
              ln -sfT ${cfg.package}/modules ${cfg.dataDir}/modules

              # opensearch needs to create the opensearch.keystore in the config directory
              # so this directory needs to be writable.
              mkdir -p ${configDir}
              chmod 0700 ${configDir}

              # Note that we copy config files from the nix store instead of symbolically linking them
              # because otherwise X-Pack Security will raise the following exception:
              # java.security.AccessControlException:
              # access denied ("java.io.FilePermission" "/var/lib/opensearch/config/opensearch.yml" "read")

              rm -f ${configDir}/opensearch.yml
              cp ${opensearchYml} ${configDir}/opensearch.yml

              # Make sure the logging configuration for old OpenSearch versions is removed:
              rm -f "${configDir}/logging.yml"
              rm -f ${configDir}/${loggingConfigFilename}
              cp ${loggingConfigFile} ${configDir}/${loggingConfigFilename}
              mkdir -p ${configDir}/scripts

              rm -f ${configDir}/jvm.options
              cp ${cfg.package}/config/jvm.options ${configDir}/jvm.options

              # redirect jvm logs to the data directory
              mkdir -p ${cfg.dataDir}/logs
              chmod 0700 ${cfg.dataDir}/logs
              sed -e 's#logs/gc.log#${cfg.dataDir}/logs/gc.log#g' -i ${configDir}/jvm.options
            '';
          in [
            "+${pkgs.writeShellScript "opensearch-start-pre-full-privileges" startPreFullPrivileges}"
            "${pkgs.writeShellScript "opensearch-start-pre-unprivileged" startPreUnprivileged}"
          ];
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("opensearch.service")
    machine.wait_for_open_port(9200)

    machine.succeed(
        "curl --fail localhost:9200"
    )
  '';
}
