# Copyright Jelle Besseling, 2024, licensed under the EUPL
{
  description = "A package collection for hosting MageOS (and Magento)";

  # Flake inputs
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";

    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2311.*.tar.gz";
  };

  # Flake outputs that other flakes can use
  outputs = { self, flake-schemas, nixpkgs }:
    let
      # Helpers for producing system-specific outputs
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      devSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = forSomeSupportedSystems supportedSystems;
      forEachDevSystem = forSomeSupportedSystems devSystems;
      forSomeSupportedSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            permittedInsecurePackages = [
              "openssl-1.1.1w" # Required by MySQL 5.7, MariaDB 10.4
            ];
            allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "elasticsearch" # Required by Elasticsearch
            ];
          };
          overlays = [
            (import ./packages/phps/phps.nix nixpkgs)
            (import ./packages/mysqls/mysqls.nix nixpkgs)
            (import ./packages/mariadbs/mariadbs.nix nixpkgs)
            (import ./packages/redises/redises.nix nixpkgs)
            (import ./packages/varnishes/varnishes.nix nixpkgs)
            (import ./packages/elasticsearches/elasticsearches.nix nixpkgs)
            (import ./packages/opensearches/opensearches.nix nixpkgs)
            (import ./packages/rabbitmqs/rabbitmqs.nix nixpkgs)
          ];
        };
      });
    in
    {
      # Schemas tell Nix about the structure of your flake's outputs
      schemas = flake-schemas.schemas;

      packages = forEachSupportedSystem ({ pkgs, ... }: {
        inherit (pkgs)
          php70 php71 php72 php73 php74 php80 php81 php82 php83
          mariadb_104 mariadb_106
          mysql57 mysql80
          redis_60 redis_62 redis_70 redis_72
          varnish64 varnish65 varnish70 varnish71 varnish73 varnish75
          elasticsearch_79 elasticsearch_716 elasticsearch_717 elasticsearch_84 elasticsearch_85 elasticsearch_811
          opensearch_12 opensearch_13 opensearch_25 opensearch_212
          rabbitmq_311 rabbitmq_312 rabbitmq_313;
      } // nixpkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
        inherit (pkgs) php56;
      });

      checks = forEachSupportedSystem ({ pkgs, ... }:
        {
          redis-nixos = (pkgs.extend (self: super: {
            redis = pkgs.redis_70;
          })).nixosTests.redis;
        });

      # Development environments
      devShells = forEachDevSystem ({ pkgs, ... }:
        let
          mkNushellScript =
            { name
            , script
            , bin ? name
            , path ? [ ]
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
                path = with pkgs; [ coreutils git rsync ];
              })
            ];
          };
        });
    };
}
