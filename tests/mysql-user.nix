projectModule:
{ pkgs, lib, ... }:
{
  name = "mariadb-user";

  nodes = {
    machine =
      { pkgs, ... }:
      {
        imports = [ projectModule ];
        projects.test = {
          services.mysql = {
            enable = true;
            package = pkgs.phpHosting.mysql."8.0";
          };
        };

        projects.foo = {
          services.mysql = {
            enable = true;
            package = pkgs.phpHosting.mysql."8.0";
          };
        };
      };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("setup-project-test.service")
    machine.wait_for_unit("mysql.service", "test")
    machine.succeed("su - test -c 'echo \"create database testing; connect testing; create table test (name int); insert into test (name) values (1);\" | mysql'")
    machine.succeed("su - test -c 'echo \"select * from test;\" | mysql testing | grep 1'")

    machine.wait_for_unit("mysql.service", "foo")
    machine.succeed("su - foo -c 'echo \"create database testing; connect testing; create table test (name int); insert into test (name) values (1);\" | mysql'")
    machine.succeed("su - foo -c 'echo \"select * from test;\" | mysql testing | grep 1'")
  '';
}
