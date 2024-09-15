{ pkgs, lib, ... }:

with lib;

let

    cfg = config.systemd;

in

{
  config = {
    system.build.systemd-units = pkgs.writeText "test-service.service" ''
      [Unit]
      Description=Test service

      [Service]
      ExecStart=${pkgs.writeText "test-script.sh" ''
        #!/bin/sh
        echo "Test"
      ''}
      Type=oneshot
      RemainAfterExit=yes
      TimeoutStartSec=5m

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
