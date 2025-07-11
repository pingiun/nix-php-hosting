# Copyright Jelle Besseling, 2024, licensed under the EUPL
{
  description = "A package collection for hosting MageOS (and Magento)";

  # Flake inputs
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";

    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2505.*.tar.gz";
  };

  # Flake outputs that other flakes can use
  outputs =
    {
      self,
      flake-schemas,
      nixpkgs,
    }:
    let
      # Helpers for producing system-specific outputs
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      devSystems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
      ];
      forEachSupportedSystem = forSomeSupportedSystems supportedSystems;
      forEachDevSystem = forSomeSupportedSystems devSystems;
      forSomeSupportedSystems =
        systems: f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              config = {
                permittedInsecurePackages = [
                  "openssl-1.1.1w" # Required by MySQL 5.7, MariaDB 10.4
                  "python-2.7.18.8" # Required by rabbitmq
                ];
                allowUnfreePredicate =
                  pkg:
                  builtins.elem (nixpkgs.lib.getName pkg) [
                    "elasticsearch" # Required by Elasticsearch
                  ];
              };
              overlays = [ self.overlays.default ];
            };
          }
        );
    in
    {
      # Schemas tell Nix about the structure of your flake's outputs
      schemas = flake-schemas.schemas;

      nixosModules = {
        magento = import ./modules/magento.nix;
        default = import ./modules/default.nix;
      };

      overlays.default = nixpkgs.lib.composeManyExtensions [
        (import ./packages/phps/phps.nix nixpkgs)
        (import ./packages/mysqls/mysqls.nix nixpkgs)
        (import ./packages/mariadbs/mariadbs.nix nixpkgs)
        (import ./packages/redises/redises.nix nixpkgs)
        (import ./packages/varnishes/varnishes.nix nixpkgs)
        (import ./packages/elasticsearches/elasticsearches.nix nixpkgs)
        (import ./packages/opensearches/opensearches.nix nixpkgs)
        (import ./packages/rabbitmqs/rabbitmqs.nix nixpkgs)
        (import ./packages/valkeys/valkeys.nix nixpkgs)
        (final: prev: {
          phpHosting = {
            php = {
              "7.0" = prev.php70;
              "7.1" = prev.php71;
              "7.2" = prev.php72;
              "7.3" = prev.php73;
              "7.4" = prev.php74;
              "8.0" = prev.php80;
              "8.1" = prev.php81;
              "8.2" = prev.php82;
              "8.3" = prev.php83;
              "8.4" = prev.php84;
            };
            mariadb = {
              "10.4" = prev.mariadb_104;
              "10.6" = prev.mariadb_106;
              "11.4" = prev.mariadb_114;
            };
            mysql = {
              "5.7" = prev.mysql57;
              "8.0" = prev.mysql80;
              "8.4" = prev.mysql84;
            };
            redis = {
              "6.0" = prev.redis_60;
              "6.2" = prev.redis_62;
              "7.0" = prev.redis_70;
              "7.2" = prev.redis_72;
            };
            valkey = {
              "8.0" = prev.valkey;
            };
            varnish = {
              "6.4" = prev.varnish64;
              "6.5" = prev.varnish65;
              "7.0" = prev.varnish70;
              "7.1" = prev.varnish71;
              "7.3" = prev.varnish73;
              "7.5" = prev.varnish75;
              "7.6" = prev.varnish76;
            };
            varnishModules = {
              "7.6" = prev.varnish76Modules;
            };
            elasticsearch = {
              "7.9" = prev.elasticsearch_79;
              "7.16" = prev.elasticsearch_716;
              "7.17" = prev.elasticsearch_717;
              "8.4" = prev.elasticsearch_84;
              "8.5" = prev.elasticsearch_85;
              "8.11" = prev.elasticsearch_811;
            };
            opensearch = {
              "1.2" = prev.opensearch_12;
              "1.3" = prev.opensearch_13;
              "2.5" = prev.opensearch_25;
              "2.12" = prev.opensearch_212;
              "2.19" = prev.opensearch_219;
            };
            rabbitmq = {
              "3.11" = prev.rabbitmq_311;
              "3.12" = prev.rabbitmq_312;
              "3.13" = prev.rabbitmq_313;
              "4.1" = prev.rabbitmq_41;
            };
          };
        })
      ];

      packages = forEachSupportedSystem (
        { pkgs, ... }:
        {
          inherit (pkgs)
            php70
            php71
            php72
            php73
            php74
            php80
            php81
            php82
            php83
            php84
            mariadb_104
            mariadb_106
            mariadb_114
            mysql57
            mysql80
            redis_60
            redis_62
            redis_70
            redis_72
            valkey_8_0
            varnish64
            varnish65
            varnish70
            varnish71
            varnish73
            varnish75
            varnish76
            varnish76Modules
            elasticsearch_79
            elasticsearch_716
            elasticsearch_717
            elasticsearch_84
            elasticsearch_85
            elasticsearch_811
            opensearch_12
            opensearch_13
            opensearch_25
            opensearch_212
            opensearch_219
            rabbitmq_311
            rabbitmq_312
            rabbitmq_313
            rabbitmq_41
            ;
        }
        // nixpkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
          inherit (pkgs) php56;
        }
      );

      checks = forEachSupportedSystem (
        { pkgs, ... }:
        with pkgs.lib;
        {
          activation = pkgs.testers.runNixOSTest (import ./tests/activation-script.nix ./modules/default.nix);
          xdg-write = pkgs.testers.runNixOSTest (import ./tests/xdg-write.nix ./modules/default.nix);
          elasticsearch-user = pkgs.testers.runNixOSTest (
            import ./tests/elasticsearch-user.nix ./modules/default.nix
          );
          mariadb-user = pkgs.testers.runNixOSTest (import ./tests/mariadb-user.nix ./modules/default.nix);
          mysql-user = pkgs.testers.runNixOSTest (import ./tests/mysql-user.nix ./modules/default.nix);
          rabbitmq-user = pkgs.testers.runNixOSTest (import ./tests/rabbitmq-user.nix ./modules/default.nix);
          redis-user = pkgs.testers.runNixOSTest (import ./tests/redis-user.nix ./modules/default.nix);
          systemd-user-unit = pkgs.testers.runNixOSTest (
            import ./tests/systemd-user-unit.nix ./modules/default.nix
          );
        }
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-redis-${replaceStrings [ "." ] [ "-" ] name}" (
            (pkgs.extend (final: prev: { redis = value; })).testers.runNixOSTest ./tests/redis.nix
          )
        ) pkgs.phpHosting.redis)
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-valkey-${replaceStrings [ "." ] [ "-" ] name}" (
            (pkgs.extend (final: prev: { redis = value; })).testers.runNixOSTest ./tests/redis.nix
          )
        ) pkgs.phpHosting.valkey)
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-mysql-${replaceStrings [ "." ] [ "-" ] name}" (
            (pkgs.extend (final: prev: { mysql = value; })).testers.runNixOSTest ./tests/mysql.nix
          )
        ) pkgs.phpHosting.mysql)
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-mariadb-${replaceStrings [ "." ] [ "-" ] name}" (
            (pkgs.extend (final: prev: { mariadb = value; })).testers.runNixOSTest ./tests/mariadb.nix
          )
        ) pkgs.phpHosting.mariadb)
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-rabbitmq-${replaceStrings [ "." ] [ "-" ] name}" (
            (pkgs.extend (final: prev: { rabbitmq-server = value; })).testers.runNixOSTest ./tests/rabbitmq.nix
          )
        ) pkgs.phpHosting.rabbitmq)
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-opensearch-${replaceStrings [ "." ] [ "-" ] name}" (
            (pkgs.extend (final: prev: { opensearch = value; })).testers.runNixOSTest ./tests/opensearch.nix
          )
        ) pkgs.phpHosting.opensearch)
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-elasticsearch-${replaceStrings [ "." ] [ "-" ] name}" (
            (pkgs.extend (final: prev: { elasticsearch = value; })).testers.runNixOSTest
              ./tests/elasticsearch.nix
          )
        ) pkgs.phpHosting.elasticsearch)
        // (mapAttrs' (
          name: value:
          nameValuePair "nixos-phpfpm-${replaceStrings [ "." ] [ "-" ] name}" (
            pkgs.testers.runNixOSTest (import ./tests/fpm.nix value)
          )
        ) pkgs.phpHosting.php)
      );

      formatter = forEachDevSystem ({ pkgs, ... }: pkgs.nixfmt-rfc-style);

      nixosConfigurations.basic-test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.default
          (
            { pkgs, lib, ... }:
            {
              nixpkgs.overlays = [ self.overlays.default ];
              services.getty.autologinUser = "test";
              users.allowNoPasswordLogin = true;

              imports = [ ./tests/elasticsearch-patched-module.nix ];
              disabledModules = [ "services/search/elasticsearch.nix" ];

              virtualisation.vmVariant = {
                # following configuration is added only when building VM with build-vm
                virtualisation = {
                  memorySize = 4096; # Use 2048MiB memory.
                  cores = 4;
                  graphics = false;
                };
              };

              projects.test = {
                services.mysql = {
                  enable = true;
                  package = pkgs.phpHosting.mariadb."10.6";
                };
                services.redis = {
                  package = pkgs.phpHosting.redis."7.2";
                  servers.default = {
                    enable = true;
                  };
                };
                services.rabbitmq = {
                  enable = true;
                  package = pkgs.phpHosting.rabbitmq."3.13";

                  managementPlugin.enable = true;
                };
                services.elasticsearch = {
                  enable = true;
                  package = pkgs.phpHosting.elasticsearch."8.11";
                };
              };
            }
          )
        ];
      };

      # Development environments
      devShells = forEachDevSystem (
        { pkgs, ... }:
        let
          mkNushellScript =
            {
              name,
              script,
              bin ? name,
              path ? [ ],
            }:

            let
              nu = "${pkgs.nushell}/bin/nu";
            in
            pkgs.writeTextFile {
              inherit name;
              destination = "/bin/${bin}";
              text = ''
                #!${nu}

                $env.PATH = (${builtins.toJSON (builtins.toJSON (map (x: "${x}/bin") path))} | from json);

                ${script}
              '';
              executable = true;
            };
        in
        {
          default = pkgs.mkShell {
            # Pinned packages available in the environment
            packages = with pkgs; [
              nixpkgs-fmt
              (mkNushellScript {
                name = "update-phps";
                script = builtins.readFile ./scripts/update-phps.nu;
                path = with pkgs; [
                  coreutils
                  git
                  rsync
                ];
              })
            ];
          };
        }
      );
    };
}
