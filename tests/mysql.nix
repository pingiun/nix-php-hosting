{ pkgs, lib, ... }:
{
  name = "mysql";
  meta = with lib.maintainers; {
    maintainers = [
      ajs124
      das_j
    ];
  };

  nodes = {
    machine =
      { pkgs, ... }:
      {

        users = {
          groups.testusers = { };

          users.testuser = {
            isSystemUser = true;
            group = "testusers";
          };

          users.testuser2 = {
            isSystemUser = true;
            group = "testusers";
          };
        };

        services.mysql = {
          enable = true;
          initialDatabases = [
            {
              name = "testdb3";
              schema = ./testdb.sql;
            }
          ];
          # note that using pkgs.writeText here is generally not a good idea,
          # as it will store the password in world-readable /nix/store ;)
          initialScript = pkgs.writeText "mysql-init.sql" ''
            CREATE USER 'testuser3'@'localhost' IDENTIFIED BY 'secure';
            GRANT ALL PRIVILEGES ON testdb3.* TO 'testuser3'@'localhost';
          '';

          ensureDatabases = [
            "testdb"
            "testdb2"
          ];
          ensureUsers = [
            {
              name = "testuser";
              ensurePermissions = {
                "testdb.*" = "ALL PRIVILEGES";
              };
            }
            {
              name = "testuser2";
              ensurePermissions = {
                "testdb2.*" = "ALL PRIVILEGES";
              };
            }
          ];
          package = pkgs.mysql;
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("mysql")
    machine.succeed(
        "echo 'use testdb; create table tests (test_id INT, PRIMARY KEY (test_id));' | sudo -u testuser mysql -u testuser"
    )
    machine.succeed(
        "echo 'use testdb; insert into tests values (42);' | sudo -u testuser mysql -u testuser"
    )
    # Ensure testuser2 is not able to insert into testdb as mysql testuser2
    machine.fail(
        "echo 'use testdb; insert into tests values (23);' | sudo -u testuser2 mysql -u testuser2"
    )
    # Ensure testuser2 is not able to authenticate as mysql testuser
    machine.fail(
        "echo 'use testdb; insert into tests values (23);' | sudo -u testuser2 mysql -u testuser"
    )
    machine.succeed(
        "echo 'use testdb; select test_id from tests;' | sudo -u testuser mysql -u testuser -N | grep 42"
    )
  '';
}
