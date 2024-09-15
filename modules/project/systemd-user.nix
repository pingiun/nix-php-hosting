{ pkgs, lib, ... }:

with lib;

let

    cfg = config.systemd;

in

{
  config = {
    system.build.systemd-units = pkgs.writeTextDir "user/testing.service" ''
      [Unit]
      Description=Test service

      [Service]
      ExecStart=${pkgs.writeShellScript "test-script.sh" ''
        echo "Test"
      ''}
      Type=oneshot
      RemainAfterExit=yes
      TimeoutStartSec=5m

      [Install]
      WantedBy=default.target
    '';
  };
}
